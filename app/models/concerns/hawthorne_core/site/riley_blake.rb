# v3.0

module HawthorneCore::Site::RileyBlake
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    CONFIG =
      {
        env_name: HawthorneCore::AppConfig::RILEY_BLAKE_ENV_SITE_NAME,
        id: 1,
        name: 'Hawthorne at Riley Blake',
        contact_email: 'hello@rileyblakeathawthorne.com',
        email_from_tagline: 'Lindsay, Charlie, and your friends at Hawthorne',
        mailer_send_welcome_template_id: 'neqvygmmvz5g0p7w'
      }.freeze

    CONFIG.each do |key, value|
      define_singleton_method(('riley_blake_' + key.to_s)) { value }
    end

    # -----------------------------------------------------------------------------

  end

end