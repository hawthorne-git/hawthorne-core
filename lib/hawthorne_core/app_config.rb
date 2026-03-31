# v3.0

# frozen_string_literal: true

module HawthorneCore

  class AppConfig

    # -----------------------------------------------------------------------------

    def self.mailer_send_api_token = fetch_env_attr('MAILER_SEND_API_TOKEN')

    def self.site_base_url = fetch_env_attr('SITE_BASE_URL')

    def self.smarty_embedded_key = fetch_env_attr('SMARTY_EMBEDDED_KEY')

    def self.twilio_password = fetch_env_attr('TWILIO_PASSWORD')

    def self.twilio_us_phone_number = fetch_env_attr('TWILIO_US_PHONE_NUMBER')

    def self.twilio_username = fetch_env_attr('TWILIO_USERNAME')

    # ----------------------------------------------------------------------------- Site Names

    RILEY_BLAKE_ENV_SITE_NAME = 'RILEY_BLAKE'

    VALID_ENV_SITE_NAMES =
      [
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