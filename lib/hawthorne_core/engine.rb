# frozen_string_literal: true

require 'rails/engine'

module HawthorneCore

  class Engine < ::Rails::Engine

    isolate_namespace HawthorneCore

    config.before_initialize do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym 'HTML'
        inflect.acronym 'UI'
      end
    end

    # verify that required hawthorne core env variables exist
    initializer 'hawthorne_core.validate_env' do
      HawthorneCore::AppConfig.aws_access_key
      HawthorneCore::AppConfig.aws_secret_access_key
      HawthorneCore::AppConfig.mailer_send_api_token
      HawthorneCore::AppConfig.rails_env
      HawthorneCore::AppConfig.redis_cache_url
      HawthorneCore::AppConfig.redis_sidekiq_url
      HawthorneCore::AppConfig.site_base_url
      HawthorneCore::AppConfig.site_name
      HawthorneCore::AppConfig.smarty_auth_id
      HawthorneCore::AppConfig.smarty_auth_token
      HawthorneCore::AppConfig.smarty_embedded_key
      HawthorneCore::AppConfig.stripe_publishable_key
      HawthorneCore::AppConfig.stripe_secret_key
      HawthorneCore::AppConfig.twilio_callback_url
      HawthorneCore::AppConfig.twilio_password
      HawthorneCore::AppConfig.twilio_username
      HawthorneCore::AppConfig.twilio_us_phone_number
    end

  end

end