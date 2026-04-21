# frozen_string_literal: true

module Api
  class MandatesController < BaseController
    def index
      mandates = Mandate.all
      mandates = mandates.where(landlord_id: params[:landlord_id]) if params[:landlord_id].present?

      render json: mandates.map { |m| mandate_json(m) }
    end

    private

    def mandate_json(mandate)
      {
        id: mandate.id,
        landlord_id: mandate.landlord_id,
        reference: mandate.reference,
        management_fee_rate: mandate.management_fee_rate,
        payment_day: mandate.payment_day,
        signed_at: mandate.signed_at,
        ended_at: mandate.ended_at,
        property_ids: mandate.properties.pluck(:id)
      }
    end
  end
end
