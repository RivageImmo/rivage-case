# frozen_string_literal: true

class Landlord < ApplicationRecord
  has_many :properties, dependent: :destroy
  has_many :leases, through: :properties
  has_many :invoices, dependent: :destroy

  enum :nature, { physical: 'physical', company: 'company' }

  validates :nature, presence: true
  validates :last_name, presence: true

  def display_name
    company? ? company_name : "#{first_name} #{last_name}"
  end

  def total_rent_cents
    leases.active.sum(:rent_amount_cents)
  end

  def total_charges_cents
    leases.active.sum(:charges_amount_cents)
  end

  def total_balance_cents
    leases.active.sum(:balance_cents)
  end

  def pending_invoices_total_cents
    invoices.pending.sum(:amount_cents)
  end

  def active_leases_count
    leases.active.count
  end

  def vacant_properties_count
    properties.left_joins(:leases).where(leases: { id: nil })
              .or(properties.left_joins(:leases).where.not(leases: { status: 'active' }))
              .distinct.count
  end
end
