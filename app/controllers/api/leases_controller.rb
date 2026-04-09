# frozen_string_literal: true

module Api
  class LeasesController < BaseController
    def index
      leases = Lease.includes(:property, :tenants, property: :landlord).order(:status, :end_date)

      render json: leases.map { |l| lease_summary(l) }
    end

    def show
      lease = Lease.includes(:property, :tenants, :payments, property: :landlord).find(params[:id])

      render json: lease_detail(lease)
    end

    private

    def lease_summary(lease)
      {
        id: lease.id,
        status: lease.status,
        lease_type: lease.lease_type,
        start_date: lease.start_date,
        end_date: lease.end_date,
        rent_amount_cents: lease.rent_amount_cents,
        charges_amount_cents: lease.charges_amount_cents,
        total_due_cents: lease.total_due_cents,
        balance_cents: lease.balance_cents,
        expires_soon: lease.expires_soon?,
        property: {
          id: lease.property.id,
          full_address: lease.property.full_address,
          city: lease.property.city,
          nature: lease.property.nature
        },
        landlord: {
          id: lease.property.landlord.id,
          display_name: lease.property.landlord.display_name
        },
        tenants: lease.tenants.map { |t| { id: t.id, display_name: t.display_name } }
      }
    end

    def lease_detail(lease)
      {
        **lease_summary(lease),
        deposit_amount_cents: lease.deposit_amount_cents,
        payments: lease.payments.order(date: :desc).map do |p|
          {
            id: p.id,
            date: p.date,
            amount_cents: p.amount_cents,
            payment_type: p.payment_type,
            payment_method: p.payment_method
          }
        end
      }
    end
  end
end
