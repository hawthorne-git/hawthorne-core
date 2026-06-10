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

    # expose hawthorne core view helpers to the host app's views unqualified
    # (isolate_namespace otherwise scopes these helpers to the engine only)
    initializer 'hawthorne_core.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        helper HawthorneCore::ImageHelper
      end
    end

    # provide the shared cloudflare r2 active storage service to every host app
    # active storage only reads config/storage.yml when service_configurations is
    # unset, so defining it here removes the need for a per-app storage.yml
    initializer 'hawthorne_core.active_storage' do |app|
      app.config.active_storage.service = :cloudflare
      app.config.active_storage.variant_processor = :disabled
      configs = app.config.active_storage.service_configurations ||= {}
      configs[:cloudflare] = {
        service: 'S3',
        access_key_id: HawthorneCore::AppConfig.r2_access_key,
        secret_access_key: HawthorneCore::AppConfig.r2_secret_access_key,
        region: 'auto',
        bucket: HawthorneCore::AppConfig.r2_bucket,
        endpoint: HawthorneCore::AppConfig.r2_endpoint,
        force_path_style: true,
        request_checksum_calculation: 'when_required',
        response_checksum_validation: 'when_required'
      }
    end

    # all hawthorne apps run in eastern time; set this before active support
    # reads config.time_zone into Time.zone_default
    initializer 'hawthorne_core.time_zone', before: 'active_support.initialize_time_zone' do |app|
      app.config.time_zone = 'Eastern Time (US & Canada)'
    end

    # verify that required hawthorne core env variables exist
    initializer 'hawthorne_core.validate_env' do
      HawthorneCore::AppConfig.mailer_send_api_token
      HawthorneCore::AppConfig.media_host
      HawthorneCore::AppConfig.r2_access_key
      HawthorneCore::AppConfig.r2_bucket
      HawthorneCore::AppConfig.r2_endpoint
      HawthorneCore::AppConfig.r2_secret_access_key
      HawthorneCore::AppConfig.rails_env
      HawthorneCore::AppConfig.redis_cache_url
      HawthorneCore::AppConfig.redis_sidekiq_url
      HawthorneCore::AppConfig.sidekiq_web_password
      HawthorneCore::AppConfig.sidekiq_web_user
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