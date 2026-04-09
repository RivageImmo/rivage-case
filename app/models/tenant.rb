# frozen_string_literal: true

class Tenant < ApplicationRecord
  has_many :lease_tenants, dependent: :destroy
  has_many :leases, through: :lease_tenants

  validates :first_name, :last_name, presence: true

  def display_name
    "#{first_name} #{last_name}"
  end
end
