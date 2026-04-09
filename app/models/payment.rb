# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :lease

  enum :payment_type, { rent: 'rent', deposit: 'deposit', regularization: 'regularization' }
  enum :payment_method, {
    bank_transfer: 'bank_transfer',
    sepa_debit: 'sepa_debit',
    check: 'check',
    caf: 'caf'
  }

  validates :date, :amount_cents, :payment_type, :payment_method, presence: true

  scope :for_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }
end
