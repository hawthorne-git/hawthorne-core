# v3.0

# frozen_string_literal: true

module HawthorneCore

  class AppConfig

    # -----------------------------------------------------------------------------

    # define the list of valid site names

    RILEY_BLAKE_SITE_NAME = 'RILEY_BLAKE'

    VALID_SITE_NAMES =
      [
        RILEY_BLAKE_SITE_NAME
      ].freeze

    # -----------------------------------------------------------------------------

    # fetch SITE_NAME ... if not found or invalid, raise an exception
    def self.site_name
      site_name = fetch_env_attr('SITE_NAME')
      raise "Invalid SITE_NAME: " + site_name unless VALID_SITE_NAMES.include?(site_name)
      site_name
    end

    # -----------------------------------------------------------------------------

    private

    # fetch an ENV attribute ... if not found, or blank, raise an exception
    def self.fetch_env_attr(key)
      raise('Missing ENV variable: ' + key) if ENV[key].blank?
      ENV[key]
    end

    # -----------------------------------------------------------------------------

  end

end