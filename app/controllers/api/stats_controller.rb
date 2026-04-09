# frozen_string_literal: true

module Api
  class StatsController < BaseController
    def index
      active_leases = Lease.active
      all_properties = Property.all

      total_rent = active_leases.sum(:rent_amount_cents)
      total_charges = active_leases.sum(:charges_amount_cents)
      total_balance = active_leases.sum(:balance_cents)
      unpaid_leases = active_leases.where('balance_cents < 0')
      expiring_leases = active_leases.where(end_date: ..30.days.from_now).where.not(end_date: nil)
      pending_invoices = Invoice.pending

      render json: {
        landlords_count: Landlord.count,
        properties_count: all_properties.count,
        active_leases_count: active_leases.count,
        vacant_properties_count: all_properties.count - active_leases.select(:property_id).distinct.count,
        occupancy_rate: all_properties.count > 0 ? ((active_leases.select(:property_id).distinct.count.to_f / all_properties.count) * 100).round(1) : 0,
        total_monthly_rent_cents: total_rent,
        total_monthly_charges_cents: total_charges,
        total_balance_cents: total_balance,
        unpaid_leases_count: unpaid_leases.count,
        total_unpaid_cents: unpaid_leases.sum(:balance_cents).abs,
        expiring_leases_count: expiring_leases.count,
        pending_invoices_count: pending_invoices.count,
        pending_invoices_total_cents: pending_invoices.sum(:amount_cents),
        disabled_payments_count: Landlord.where(payment_enabled: false).count
      }
    end
  end
end
