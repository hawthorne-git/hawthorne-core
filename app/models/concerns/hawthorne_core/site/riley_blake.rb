# v3.0

module HawthorneCore::Site::RileyBlake
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def self.riley_blake_env_name
      HawthorneCore::AppConfig::RILEY_BLAKE_ENV_SITE_NAME
    end

    def self.riley_blake_id
      50
    end

    def self.riley_blake_name
      'Hawthorne at Riley Blake'
    end

    # -----------------------------------------------------------------------------

  end

end