# frozen_string_literal: true

class Mandate < ApplicationRecord
  belongs_to :landlord
  has_many :properties, dependent: :nullify
  has_many :leases, through: :properties

  validates :reference, :signed_at, presence: true

  scope :active, -> { where(ended_at: nil).or(where('ended_at > ?', Date.current)) }
end
