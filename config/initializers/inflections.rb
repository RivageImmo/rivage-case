# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'lease_tenant', 'lease_tenants'
end
