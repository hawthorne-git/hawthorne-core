# v3.0

# frozen_string_literal: true

module HawthorneCore

  class AppConfig

    # -----------------------------------------------------------------------------

    def self.aws_access_key = fetch_env_attr('AWS_ACCESS_KEY')

    def self.aws_secret_access_key = fetch_env_attr('AWS_SECRET_ACCESS_KEY')

    def self.mailer_send_api_token = fetch_env_attr('MAILER_SEND_API_TOKEN')

    def self.redis_cache_url = fetch_env_attr('REDIS_CACHE_URL')

    def self.redis_sidekiq_url = fetch_env_attr('REDIS_SIDEKIQ_URL')

    def self.rails_env = fetch_env_attr('RAILS_ENV')

    def self.site_base_url = fetch_env_attr('SITE_BASE_URL')

    def self.smarty_auth_id = fetch_env_attr('SMARTY_AUTH_ID')

    def self.smarty_auth_token = fetch_env_attr('SMARTY_AUTH_TOKEN')

    def self.smarty_embedded_key = fetch_env_attr('SMARTY_EMBEDDED_KEY')

    def self.stripe_secret_key = fetch_env_attr('STRIPE_SECRET_KEY')

    def self.twilio_password = fetch_env_attr('TWILIO_PASSWORD')

    def self.twilio_username = fetch_env_attr('TWILIO_USERNAME')

    # ----------------------------------------------------------------------------- Site Names

    HAWTHORNE_ADMIN_ENV_SITE_NAME = 'HAWTHORNE_ADMIN'
    HAWTHORNE_ARTISTS_ENV_SITE_NAME = 'HAWTHORNE_ARTISTS'
    HAWTHORNE_PRINT_CO_ENV_SITE_NAME = 'HAWTHORNE_PRINT_CO'
    HAWTHORNE_SUPPLY_CO_ENV_SITE_NAME = 'HAWTHORNE_SUPPLY_CO'
    RILEY_BLAKE_ENV_SITE_NAME = 'RILEY_BLAKE'

    VALID_ENV_SITE_NAMES =
      [
        HAWTHORNE_ADMIN_ENV_SITE_NAME,
        HAWTHORNE_ARTISTS_ENV_SITE_NAME,
        HAWTHORNE_PRINT_CO_ENV_SITE_NAME,
        HAWTHORNE_SUPPLY_CO_ENV_SITE_NAME,
        RILEY_BLAKE_ENV_SITE_NAME
      ].freeze

    def self.site_name
      site_name = fetch_env_attr('SITE_NAME')
      raise "Invalid SITE_NAME: #{site_name}" unless VALID_ENV_SITE_NAMES.include?(site_name)
      site_name
    end

    # -----------------------------------------------------------------------------

    private

    # fetch an ENV attribute ... if not found, or blank, raise an exception
    def self.fetch_env_attr(key)
      raise("Missing ENV variable: #{key}") if ENV[key].blank?
      ENV[key]
    end

    # -----------------------------------------------------------------------------

  end

end