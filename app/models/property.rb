# frozen_string_literal: true

class Property < ApplicationRecord
  belongs_to :landlord
  has_many :leases, dependent: :destroy
  has_many :invoices, dependent: :destroy

  enum :nature, {
    apartment: 'apartment',
    house: 'house',
    commercial: 'commercial',
    parking: 'parking'
  }

  validates :address, :city, :zip_code, :nature, presence: true

  def full_address
    [address, unit_number].compact.join(', ')
  end

  def active_lease
    leases.find_by(status: 'active')
  end

  def vacant?
    active_lease.nil?
  end
end
