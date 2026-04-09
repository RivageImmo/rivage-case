# frozen_string_literal: true

class LeaseTenant < ApplicationRecord
  belongs_to :lease
  belongs_to :tenant
end
