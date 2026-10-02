# frozen_string_literal: true

module HawthorneCore

  class AppConfig

    # -----------------------------------------------------------------------------

    def self.mailer_send_api_token = fetch_env_attr('MAILER_SEND_API_TOKEN')

    def self.media_host  = fetch_env_attr('MEDIA_HOST')

    def self.r2_access_key = fetch_env_attr('R2_ACCESS_KEY')

    def self.r2_bucket  = fetch_env_attr('R2_BUCKET')

    def self.r2_endpoint  = fetch_env_attr('R2_ENDPOINT')

    def self.r2_secret_access_key = fetch_env_attr('R2_SECRET_ACCESS_KEY')

    def self.redis_cache_url = fetch_env_attr('REDIS_CACHE_URL')

    def self.redis_cache_namespace = site_env_name.downcase

    def self.redis_sidekiq_url = fetch_env_attr('REDIS_SIDEKIQ_URL')

    def self.rails_env = fetch_env_attr('RAILS_ENV')

    def self.sidekiq_web_password = fetch_env_attr('SIDEKIQ_WEB_PASSWORD')

    def self.sidekiq_web_user = fetch_env_attr('SIDEKIQ_WEB_USER')

    def self.site_base_url = fetch_env_attr('SITE_BASE_URL')

    # matches the env handle of a site in the database, ex: HAWTHORNE_PRINT_CO
    def self.site_env_name = fetch_env_attr('SITE_ENV_NAME')

    # SITE_LOCKED must be TRUE or FALSE ... raise on anything else so a typo never unlocks the site
    def self.site_locked?
      site_locked = fetch_env_attr('SITE_LOCKED')
      raise "Invalid SITE_LOCKED: #{site_locked}" unless %w[TRUE FALSE].include?(site_locked)
      site_locked == 'TRUE'
    end

    def self.site_lock_key = fetch_env_attr('SITE_LOCK_KEY')

    def self.smarty_auth_id = fetch_env_attr('SMARTY_AUTH_ID')

    def self.smarty_auth_token = fetch_env_attr('SMARTY_AUTH_TOKEN')

    def self.smarty_embedded_key = fetch_env_attr('SMARTY_EMBEDDED_KEY')

    def self.stripe_publishable_key = fetch_env_attr('STRIPE_PUBLISHABLE_KEY')

    def self.stripe_secret_key = fetch_env_attr('STRIPE_SECRET_KEY')

    def self.twilio_callback_url = fetch_env_attr('TWILIO_CALLBACK_URL')

    def self.twilio_password = fetch_env_attr('TWILIO_PASSWORD')

    def self.twilio_username = fetch_env_attr('TWILIO_USERNAME')

    def self.twilio_us_phone_number = fetch_env_attr('TWILIO_US_PHONE_NUMBER')

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