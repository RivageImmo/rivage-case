# frozen_string_literal: true

module Api
  # Liste les données brutes nécessaires pour construire la revue mensuelle
  # des versements propriétaires.
  #
  # CE CONTRÔLEUR NE REND AUCUN VERDICT. Il n'y a ni montant proposé, ni status
  # (ready / at_risk / blocked), ni liste de signaux. Ces éléments sont à la
  # charge du candidat : à partir des briques métier brutes, il doit
  #   - calculer le net à verser (encaissements × mandats × honoraires − factures − DG)
  #   - identifier les situations qui méritent une alerte
  #   - classer et prioriser les propositions
  #   - construire l'UX de décision (valider / bloquer / ajuster)
  #
  # Convention temporelle : on est le 8 avril 2026. Le lot de versements du
  # 10 avril concerne les loyers de mars 2026 encaissés.
  class PayoutsController < BaseController
    REFERENCE_DATE = Date.new(2026, 4, 8)
    COLLECTION_MONTH = Date.new(2026, 3, 1)

    def index
      landlords = Landlord.includes(
        :mandates,
        properties: { leases: %i[tenants payments] },
        invoices: :property
      ).order(:last_name)

      render json: {
        period: {
          reference_date: REFERENCE_DATE,
          scheduled_for: Date.new(2026, 4, 10),
          collection_month: COLLECTION_MONTH.strftime('%Y-%m'),
          collection_month_label: format_month(COLLECTION_MONTH)
        },
        agency_defaults: {
          # Appliqués quand un mandat a management_fee_rate ou payment_day à null.
          management_fee_rate: 7.0,
          payment_day: 10
        },
        landlords: landlords.map { |l| landlord_payload(l) }
      }
    end

    private

    MONTH_NAMES_FR = %w[Janvier Février Mars Avril Mai Juin Juillet Août Septembre Octobre Novembre Décembre].freeze

    def format_month(date)
      "#{MONTH_NAMES_FR[date.month - 1]} #{date.year}"
    end

    def landlord_payload(landlord)
      {
        id: landlord.id,
        nature: landlord.nature,
        display_name: landlord.display_name,
        company_name: landlord.company_name,
        siret: landlord.siret,
        email: landlord.email,
        phone: landlord.phone,
        payment_enabled: landlord.payment_enabled,
        payment_disabled_reason: landlord.payment_disabled_reason,
        mandate_started_at: landlord.created_at.to_date,
        mandates: landlord.mandates.map { |m| mandate_payload(m) },
        properties: landlord.properties.map { |p| property_payload(p) },
        invoices: landlord.invoices.map { |i| invoice_payload(i) }
      }
    end

    def mandate_payload(mandate)
      {
        id: mandate.id,
        reference: mandate.reference,
        management_fee_rate: mandate.management_fee_rate,
        payment_day: mandate.payment_day,
        signed_at: mandate.signed_at,
        ended_at: mandate.ended_at,
        property_ids: mandate.properties.map(&:id)
      }
    end

    def property_payload(property)
      {
        id: property.id,
        full_address: property.full_address,
        city: property.city,
        nature: property.nature,
        mandate_id: property.mandate_id,
        leases: property.leases.map { |l| lease_payload(l) }
      }
    end

    def lease_payload(lease)
      {
        id: lease.id,
        status: lease.status,
        lease_type: lease.lease_type,
        start_date: lease.start_date,
        end_date: lease.end_date,
        rent_amount_cents: lease.rent_amount_cents,
        charges_amount_cents: lease.charges_amount_cents,
        total_due_cents: lease.total_due_cents,
        deposit_amount_cents: lease.deposit_amount_cents,
        balance_cents: lease.balance_cents,
        tenants: lease.tenants.map { |t| tenant_payload(t, lease) },
        payments_collection_month: lease.payments.select do |p|
          p.date >= COLLECTION_MONTH.beginning_of_month &&
            p.date <= COLLECTION_MONTH.end_of_month
        end.map { |p| payment_payload(p) },
        payments_post_month: lease.payments.select do |p|
          p.date > COLLECTION_MONTH.end_of_month && p.date <= REFERENCE_DATE
        end.map { |p| payment_payload(p) }
      }
    end

    def tenant_payload(tenant, lease)
      lt = lease.lease_tenants.find { |x| x.tenant_id == tenant.id }
      {
        id: tenant.id,
        display_name: tenant.display_name,
        email: tenant.email,
        phone: tenant.phone,
        caf_amount_cents: tenant.caf_amount_cents,
        share: lt&.share
      }
    end

    def payment_payload(payment)
      {
        id: payment.id,
        date: payment.date,
        amount_cents: payment.amount_cents,
        payment_type: payment.payment_type,
        payment_method: payment.payment_method
      }
    end

    def invoice_payload(invoice)
      {
        id: invoice.id,
        supplier_name: invoice.supplier_name,
        description: invoice.description,
        amount_cents: invoice.amount_cents,
        status: invoice.status,
        due_date: invoice.due_date,
        paid_date: invoice.paid_date,
        property_id: invoice.property_id,
        property_address: invoice.property&.full_address
      }
    end
  end
end
