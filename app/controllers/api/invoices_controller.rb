# frozen_string_literal: true

module Api
  class InvoicesController < BaseController
    def index
      invoices = Invoice.includes(:landlord, :property).order(due_date: :desc)

      render json: invoices.map { |i| invoice_json(i) }
    end

    private

    def invoice_json(invoice)
      {
        id: invoice.id,
        supplier_name: invoice.supplier_name,
        description: invoice.description,
        amount_cents: invoice.amount_cents,
        status: invoice.status,
        due_date: invoice.due_date,
        paid_date: invoice.paid_date,
        landlord: {
          id: invoice.landlord.id,
          display_name: invoice.landlord.display_name
        },
        property_address: invoice.property&.full_address
      }
    end
  end
end
