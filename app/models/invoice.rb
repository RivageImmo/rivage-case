# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :landlord
  belongs_to :property, optional: true

  enum :status, { pending: 'pending', paid: 'paid' }

  validates :supplier_name, :description, :amount_cents, :status, :due_date, presence: true

  scope :pending, -> { where(status: 'pending') }
end
