# frozen_string_literal: true

module Api
  class LandlordsController < BaseController
    COLLECTION_MONTH = Date.new(2026, 3, 1)
    REFERENCE_DATE = Date.new(2026, 4, 8)

    def index
      landlords = Landlord.includes(
        :mandates,
        properties: { leases: %i[tenants payments] },
        invoices: :property
      ).order(:last_name)

      render json: landlords.map { |l| landlord_summary(l) }
    end

    def show
      landlord = Landlord.includes(
        :mandates,
        properties: { leases: %i[tenants payments] },
        invoices: :property
      ).find(params[:id])

      render json: landlord_detail(landlord)
    end

    private

    def landlord_summary(landlord)
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
        mandates: landlord.mandates.map { |m| mandate_json(m) },
        properties: landlord.properties.map { |p| property_json(p) },
        invoices: landlord.invoices.map { |i| invoice_json(i) }
      }
    end

    def landlord_detail(landlord)
      landlord_summary(landlord)
    end

    def mandate_json(mandate)
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

    def property_json(property)
      {
        id: property.id,
        full_address: property.full_address,
        city: property.city,
        nature: property.nature,
        mandate_id: property.mandate_id,
        leases: property.leases.map { |l| lease_json(l) }
      }
    end

    def lease_json(lease)
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
        tenants: lease.tenants.map { |t| tenant_json(t, lease) },
        payments_collection_month: lease.payments.select do |p|
          p.date >= COLLECTION_MONTH.beginning_of_month &&
            p.date <= COLLECTION_MONTH.end_of_month
        end.map { |p| payment_json(p) },
        payments_post_month: lease.payments.select do |p|
          p.date > COLLECTION_MONTH.end_of_month && p.date <= REFERENCE_DATE
        end.map { |p| payment_json(p) }
      }
    end

    def tenant_json(tenant, lease)
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

    def payment_json(payment)
      {
        id: payment.id,
        date: payment.date,
        amount_cents: payment.amount_cents,
        payment_type: payment.payment_type,
        payment_method: payment.payment_method
      }
    end

    def invoice_json(invoice)
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
