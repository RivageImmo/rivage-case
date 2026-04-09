# frozen_string_literal: true

module Api
  class PropertiesController < BaseController
    def index
      properties = Property.includes(:landlord, leases: :tenants).all

      render json: properties.map { |p| property_json(p) }
    end

    private

    def property_json(property)
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
        landlord: {
          id: property.landlord.id,
          display_name: property.landlord.display_name
        },
        tenant: active_lease&.tenants&.first ? {
          id: active_lease.tenants.first.id,
          display_name: active_lease.tenants.first.display_name
        } : nil,
        rent_amount_cents: active_lease&.rent_amount_cents,
        balance_cents: active_lease&.balance_cents
      }
    end
  end
end
