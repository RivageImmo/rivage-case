# frozen_string_literal: true

module Api
  class LandlordsController < BaseController
    def index
      landlords = Landlord.includes(properties: { leases: :tenants }).all

      render json: landlords.map { |l| landlord_summary(l) }
    end

    def show
      landlord = Landlord.includes(
        properties: { leases: [:tenants, :payments] },
        invoices: :property
      ).find(params[:id])

      render json: landlord_detail(landlord)
    end

    private

    def landlord_summary(landlord)
      active_leases = landlord.leases.select(&:active?)

      {
        id: landlord.id,
        nature: landlord.nature,
        display_name: landlord.display_name,
        company_name: landlord.company_name,
        email: landlord.email,
        phone: landlord.phone,
        payment_day: landlord.payment_day,
        management_fee_rate: landlord.management_fee_rate,
        payment_enabled: landlord.payment_enabled,
        payment_disabled_reason: landlord.payment_disabled_reason,
        properties_count: landlord.properties.size,
        active_leases_count: active_leases.size,
        vacant_properties_count: landlord.properties.size - active_leases.map(&:property_id).uniq.size,
        total_rent_cents: active_leases.sum(&:rent_amount_cents),
        total_charges_cents: active_leases.sum(&:charges_amount_cents),
        total_balance_cents: active_leases.sum(&:balance_cents),
        pending_invoices_cents: landlord.invoices.select(&:pending?).sum(&:amount_cents),
        has_expiring_lease: active_leases.any? { |l| l.end_date.present? && l.end_date <= 30.days.from_now }
      }
    end

    def landlord_detail(landlord)
      {
        **landlord_summary(landlord),
        siret: landlord.siret,
        properties: landlord.properties.map { |p| property_with_lease(p) },
        invoices: landlord.invoices.order(due_date: :desc).map { |i| invoice_json(i) }
      }
    end

    def property_with_lease(property)
      active_lease = property.leases.find(&:active?)
      {
        id: property.id,
        address: property.address,
        unit_number: property.unit_number,
        full_address: property.full_address,
        city: property.city,
        zip_code: property.zip_code,
        nature: property.nature,
        area_sqm: property.area_sqm,
        rooms_count: property.rooms_count,
        vacant: active_lease.nil?,
        lease: active_lease ? lease_json(active_lease) : nil
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
        deposit_amount_cents: lease.deposit_amount_cents,
        total_due_cents: lease.total_due_cents,
        balance_cents: lease.balance_cents,
        expires_soon: lease.expires_soon?,
        tenants: lease.tenants.map { |t| tenant_json(t, lease) },
        recent_payments: lease.payments.order(date: :desc).first(6).map { |p| payment_json(p) }
      }
    end

    def tenant_json(tenant, lease)
      lt = lease.lease_tenants.find { |lt| lt.tenant_id == tenant.id }
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
        property_address: invoice.property&.full_address
      }
    end
  end
end
