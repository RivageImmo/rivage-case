# frozen_string_literal: true

module Api
  # Génère la "run des versements" du mois en cours.
  #
  # Le candidat ne doit PAS refaire les calculs ici : il construit la UX de
  # décision à partir des propositions pré-calculées retournées par cet endpoint.
  #
  # Convention temporelle : on est le 8 avril 2026. La run du 10 avril concerne
  # les loyers de mars 2026 encaissés. Chaque proposition représente le montant
  # à reverser à un propriétaire, avec son breakdown, ses signaux de risque,
  # et les actions possibles (validate / block / adjust).
  class PayoutRunsController < BaseController
    REFERENCE_DATE = Date.new(2026, 4, 8)
    REFERENCE_MONTH = Date.new(2026, 3, 1) # mois de collecte des loyers
    PREVIOUS_MONTH = Date.new(2026, 2, 1)
    DEFAULT_FEE_RATE = 7.0
    SEPA_SETTLEMENT_DAYS = 5

    def current
      landlords = Landlord.includes(
        properties: { leases: %i[tenants payments] },
        invoices: :property
      ).all

      payouts = landlords.map { |l| build_payout(l) }.compact

      render json: {
        run: run_metadata(payouts),
        payouts: payouts.sort_by { |p| status_weight(p[:proposed_status]) }
      }
    end

    private

    def run_metadata(payouts)
      {
        id: 'run-2026-04-10',
        scheduled_for: Date.new(2026, 4, 10),
        reference_date: REFERENCE_DATE,
        collection_month: REFERENCE_MONTH.strftime('%Y-%m'),
        collection_month_label: format_month(REFERENCE_MONTH),
        totals: {
          proposed_count: payouts.size,
          ready_count: payouts.count { |p| p[:proposed_status] == 'ready' },
          at_risk_count: payouts.count { |p| p[:proposed_status] == 'at_risk' },
          blocked_count: payouts.count { |p| p[:proposed_status] == 'blocked' },
          debtor_count: payouts.count { |p| p[:proposed_status] == 'debtor' },
          proposed_amount_cents: payouts.sum { |p| [p[:proposed_amount_cents], 0].max }
        }
      }
    end

    def status_weight(status)
      { 'blocked' => 0, 'debtor' => 1, 'at_risk' => 2, 'ready' => 3 }.fetch(status, 4)
    end

    def build_payout(landlord)
      active_leases = landlord.leases.select(&:active?)
      upcoming_leases = landlord.leases.select(&:upcoming?)
      breakdown = compute_breakdown(landlord, active_leases, upcoming_leases)
      signals = detect_signals(landlord, active_leases, upcoming_leases, breakdown)
      previous_amount = compute_previous_month_net(landlord)

      proposed_amount = breakdown.values.sum
      status = compute_status(landlord, proposed_amount, signals)

      {
        id: "payout-#{landlord.id}",
        landlord: landlord_summary(landlord),
        period: {
          month: REFERENCE_MONTH.strftime('%Y-%m'),
          label: format_month(REFERENCE_MONTH)
        },
        proposed_status: status,
        proposed_amount_cents: proposed_amount,
        previous_amount_cents: previous_amount,
        amount_delta_cents: previous_amount ? proposed_amount - previous_amount : nil,
        breakdown: breakdown,
        components: build_components(landlord, active_leases, upcoming_leases, breakdown),
        signals: signals,
        suggested_block_reason: landlord.payment_enabled ? nil : landlord.payment_disabled_reason,
        actions: landlord.payment_enabled ? %w[validate block adjust] : %w[acknowledge]
      }
    end

    MONTH_NAMES_FR = %w[Janvier Février Mars Avril Mai Juin Juillet Août Septembre Octobre Novembre Décembre].freeze

    def format_month(date)
      "#{MONTH_NAMES_FR[date.month - 1]} #{date.year}"
    end

    def landlord_summary(landlord)
      {
        id: landlord.id,
        nature: landlord.nature,
        display_name: landlord.display_name,
        email: landlord.email,
        phone: landlord.phone,
        payment_day: landlord.payment_day,
        management_fee_rate: landlord.management_fee_rate || DEFAULT_FEE_RATE,
        payment_enabled: landlord.payment_enabled,
        payment_disabled_reason: landlord.payment_disabled_reason,
        is_company: landlord.company?,
        mandate_started_at: landlord.created_at.to_date,
        properties_count: landlord.properties.size,
        active_leases_count: landlord.leases.count(&:active?)
      }
    end

    # --- Calculs financiers ---

    def compute_breakdown(landlord, active_leases, upcoming_leases)
      rent_collected = active_leases.sum { |l| rent_for_month(l, REFERENCE_MONTH) }
      deposit_inflow = upcoming_leases.sum { |l| deposit_collected(l) } +
                       active_leases.sum { |l| recent_deposit(l) }
      regularizations = active_leases.sum { |l| regularization_for_month(l, REFERENCE_MONTH) }

      fee_rate = (landlord.management_fee_rate || DEFAULT_FEE_RATE).to_f
      fees = -active_leases.sum { |l| (rent_for_month(l, REFERENCE_MONTH) * fee_rate / 100.0).round }

      invoices_deducted = -landlord.invoices.select { |i| deduct_invoice?(i) }.sum(&:amount_cents)
      carryover = -past_debtor_carryover(landlord)
      deposit_refund = -pending_deposit_refund(landlord)

      {
        rent_collected_cents: rent_collected,
        deposit_inflow_cents: deposit_inflow,
        regularization_cents: regularizations,
        fees_cents: fees,
        invoices_cents: invoices_deducted,
        deposit_refund_cents: deposit_refund,
        carryover_cents: carryover
      }
    end

    # Loyers encaissés pour un mois donné sur un bail, en tenant compte des
    # rejets SEPA (paiements négatifs) qui annulent l'encaissement.
    def rent_for_month(lease, month)
      range = month.beginning_of_month..month.end_of_month
      rent_payments = lease.payments.select do |p|
        p.rent? && range.cover?(p.date)
      end
      # Paiements SEPA rejetés (contrepartie négative datée post-mois)
      rejections = lease.payments.select do |p|
        p.rent? && p.sepa_debit? && p.amount_cents.negative? && p.date > month.end_of_month
      end
      rent_payments.sum(&:amount_cents) + rejections.sum(&:amount_cents)
    end

    def regularization_for_month(lease, month)
      range = month.beginning_of_month..month.end_of_month
      lease.payments.select { |p| p.regularization? && range.cover?(p.date) }.sum(&:amount_cents)
    end

    def deposit_collected(lease)
      lease.payments.select { |p| p.deposit? && p.amount_cents.positive? }.sum(&:amount_cents)
    end

    def recent_deposit(lease)
      lease.payments
           .select { |p| p.deposit? && p.date >= REFERENCE_MONTH.beginning_of_month }
           .sum(&:amount_cents)
    end

    # Factures déductibles ce mois-ci : pending dont la due_date est passée
    # ou tombe avant la prochaine run, OU paid dans le mois de référence.
    def deduct_invoice?(invoice)
      return true if invoice.paid? && invoice.paid_date.present? &&
                     invoice.paid_date.between?(REFERENCE_MONTH.beginning_of_month, REFERENCE_DATE)
      return true if invoice.pending? && invoice.due_date <= REFERENCE_DATE + 15.days

      false
    end

    # Reconstruit un déficit reporté : si le mois précédent a donné un solde
    # négatif (plus de factures payées que de loyers encaissés après honoraires),
    # on le reporte ici.
    def past_debtor_carryover(landlord)
      prev_rent = landlord.leases.select(&:active?)
                          .sum { |l| rent_for_month(l, PREVIOUS_MONTH) }
      return 0 if prev_rent.zero?

      fee_rate = (landlord.management_fee_rate || DEFAULT_FEE_RATE).to_f
      prev_fees = (prev_rent * fee_rate / 100.0).round
      prev_invoices = landlord.invoices.select do |i|
        i.paid? && i.paid_date.present? &&
          i.paid_date.between?(PREVIOUS_MONTH.beginning_of_month, PREVIOUS_MONTH.end_of_month)
      end.sum(&:amount_cents)

      deficit = prev_invoices - (prev_rent - prev_fees)
      [deficit, 0].max
    end

    # DG à restituer : bail récemment terminé dont le DG n'a pas été remboursé.
    def pending_deposit_refund(landlord)
      landlord.leases.select { |l| l.terminated? && l.end_date && l.end_date >= PREVIOUS_MONTH }
              .sum(&:deposit_amount_cents)
    end

    def compute_previous_month_net(landlord)
      active_leases = landlord.leases.select(&:active?)
      rent = active_leases.sum { |l| rent_for_month(l, PREVIOUS_MONTH) }
      return nil if rent.zero?

      fee_rate = (landlord.management_fee_rate || DEFAULT_FEE_RATE).to_f
      fees = (rent * fee_rate / 100.0).round
      invoices = landlord.invoices.select do |i|
        i.paid? && i.paid_date&.between?(PREVIOUS_MONTH.beginning_of_month, PREVIOUS_MONTH.end_of_month)
      end.sum(&:amount_cents)

      rent - fees - invoices
    end

    # --- Détection des signaux ---

    def detect_signals(landlord, active_leases, upcoming_leases, breakdown)
      signals = []
      signals << :payment_disabled unless landlord.payment_enabled
      signals << :multi_property if landlord.properties.size >= 2
      signals << :new_landlord if landlord.created_at >= REFERENCE_DATE - 30.days

      active_leases.each do |lease|
        signals << :unpaid_balance if lease.balance_cents.negative?
        signals << :expiring_lease if lease.end_date && lease.end_date <= REFERENCE_DATE + 30.days
        signals << :commercial_lease if lease.commercial?
        signals << :caf_only if caf_only?(lease)
        signals << :sepa_rejected if sepa_rejected?(lease)
        signals << :rent_partial if rent_partial?(lease)
        signals << :multi_installment if multi_installment?(lease)
        signals << :new_lease if lease.start_date >= REFERENCE_MONTH.beginning_of_month
        signals << :regularization_pending if regularization_for_month(lease, REFERENCE_MONTH).negative?
      end

      signals << :vacancy if landlord.properties.any? { |p| p.leases.none?(&:active?) }
      signals << :deposit_to_refund if breakdown[:deposit_refund_cents].negative?
      signals << :debtor_carryover if breakdown[:carryover_cents].negative?
      signals << :heavy_invoice if landlord.invoices.any? { |i| i.pending? && i.amount_cents >= 500_000 }
      signals << :upcoming_lease if upcoming_leases.any?

      signals.uniq
    end

    def caf_only?(lease)
      current = REFERENCE_MONTH.beginning_of_month..REFERENCE_MONTH.end_of_month
      payments = lease.payments.select { |p| p.rent? && current.cover?(p.date) }
      return false if payments.empty?

      payments.all?(&:caf?)
    end

    def sepa_rejected?(lease)
      lease.payments.any? { |p| p.rent? && p.sepa_debit? && p.amount_cents.negative? }
    end

    def rent_partial?(lease)
      collected = rent_for_month(lease, REFERENCE_MONTH)
      return false if collected.zero?

      collected < lease.total_due_cents
    end

    # Détecte le piège "multi-échéances" : mois précédent surperçu, mois courant vide.
    def multi_installment?(lease)
      current = rent_for_month(lease, REFERENCE_MONTH)
      previous = rent_for_month(lease, PREVIOUS_MONTH)
      return false if previous < lease.total_due_cents * 1.5

      current.zero?
    end

    def compute_status(landlord, proposed_amount, signals)
      return 'blocked' unless landlord.payment_enabled
      return 'debtor' if proposed_amount.negative?
      return 'at_risk' if risky_signal?(signals)

      'ready'
    end

    def risky_signal?(signals)
      (signals & %i[sepa_rejected caf_only rent_partial deposit_to_refund
                    heavy_invoice debtor_carryover expiring_lease regularization_pending
                    new_landlord multi_installment upcoming_lease new_lease
                    unpaid_balance payment_disabled]).any?
    end

    # --- Lignes de breakdown affichables ---

    def build_components(landlord, active_leases, upcoming_leases, _breakdown)
      components = []

      active_leases.each do |lease|
        collected = rent_for_month(lease, REFERENCE_MONTH)
        expected = lease.total_due_cents

        if collected != 0
          components << {
            type: 'rent',
            label: "Loyer encaissé — #{lease.property.full_address}",
            amount_cents: collected,
            expected_cents: expected,
            note: collected < expected ? 'Encaissement partiel' : nil,
            lease_id: lease.id
          }
        elsif lease.active?
          components << {
            type: 'rent_missing',
            label: "Aucun encaissement — #{lease.property.full_address}",
            amount_cents: 0,
            expected_cents: expected,
            lease_id: lease.id
          }
        end

        regul = regularization_for_month(lease, REFERENCE_MONTH)
        next if regul.zero?

        components << {
          type: 'regularization',
          label: "Régularisation de charges — #{lease.property.full_address}",
          amount_cents: regul,
          lease_id: lease.id
        }
      end

      upcoming_leases.each do |lease|
        deposit = deposit_collected(lease)
        next if deposit.zero?

        components << {
          type: 'deposit',
          label: "Dépôt de garantie entrant — #{lease.property.full_address}",
          amount_cents: deposit,
          note: "Bail démarre le #{lease.start_date.strftime('%d/%m/%Y')}",
          lease_id: lease.id
        }
      end

      # Honoraires
      rent_base = active_leases.sum { |l| rent_for_month(l, REFERENCE_MONTH) }
      fee_rate = (landlord.management_fee_rate || DEFAULT_FEE_RATE).to_f
      fees = (rent_base * fee_rate / 100.0).round
      components << {
        type: 'fees',
        label: "Honoraires de gestion (#{fee_rate.to_s.sub('.0', '')}%)",
        amount_cents: -fees
      } if fees.positive?

      # Factures
      landlord.invoices.select { |i| deduct_invoice?(i) }.each do |inv|
        components << {
          type: 'invoice',
          label: "#{inv.supplier_name} — #{inv.description}",
          amount_cents: -inv.amount_cents,
          due_date: inv.due_date,
          status: inv.status,
          invoice_id: inv.id
        }
      end

      # Carryover
      carryover = past_debtor_carryover(landlord)
      if carryover.positive?
        components << {
          type: 'carryover',
          label: 'Report du solde débiteur du mois précédent',
          amount_cents: -carryover
        }
      end

      # DG à restituer
      refund = pending_deposit_refund(landlord)
      if refund.positive?
        components << {
          type: 'deposit_refund',
          label: 'Dépôt de garantie à restituer (bail terminé)',
          amount_cents: -refund
        }
      end

      components
    end
  end
end
