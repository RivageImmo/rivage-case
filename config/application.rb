# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module RivageCase
  class Application < Rails::Application
    config.load_defaults 8.0
    config.time_zone = 'Europe/Paris'
    config.i18n.default_locale = :fr
  end
end
