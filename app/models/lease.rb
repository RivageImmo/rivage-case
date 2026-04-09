# frozen_string_literal: true

class Lease < ApplicationRecord
  belongs_to :property
  has_one :landlord, through: :property
  has_many :lease_tenants, dependent: :destroy
  has_many :tenants, through: :lease_tenants
  has_many :payments, dependent: :destroy

  enum :status, { active: 'active', terminated: 'terminated', upcoming: 'upcoming' }
  enum :lease_type, {
    residential_unfurnished: 'residential_unfurnished',
    residential_furnished: 'residential_furnished',
    commercial: 'commercial'
  }

  validates :status, :lease_type, :start_date, :rent_amount_cents, presence: true

  scope :active, -> { where(status: 'active') }
  scope :expiring_soon, -> { active.where(end_date: ..30.days.from_now).where.not(end_date: nil) }

  def total_due_cents
    rent_amount_cents + charges_amount_cents
  end

  def primary_tenant
    tenants.first
  end

  def expires_soon?
    active? && end_date.present? && end_date <= 30.days.from_now
  end
end
