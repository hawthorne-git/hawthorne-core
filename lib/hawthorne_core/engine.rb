# frozen_string_literal: true

require 'rails/engine'

module HawthorneCore

  class Engine < ::Rails::Engine

    isolate_namespace HawthorneCore

    # verify that required hawthorne core env variables exist
    initializer 'hawthorne_core.validate_env' do
      HawthorneCore::AppConfig.mailer_send_api_token
      HawthorneCore::AppConfig.site_base_url
      HawthorneCore::AppConfig.site_name
      HawthorneCore::AppConfig.twilio_password
      HawthorneCore::AppConfig.twilio_us_phone_number
      HawthorneCore::AppConfig.twilio_username
    end

  end

end