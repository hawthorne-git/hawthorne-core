# v3.0

module HawthorneCore::Site::HawthorneSupplyCo
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    #TODO: change id, contact_email, and mailer_send_welcome_template_id
    CONFIG =
      {
        env_name: HawthorneCore::AppConfig::HAWTHORNE_SUPPLY_CO_ENV_SITE_NAME,
        id: 1,
        name: 'Hawthorne Supply Co',
        site_sharing_scope: 'HAWTHORNE',
        has_checkout: true,
        contact_email: 'contact@hawthornesupplyco.com',
        email_from_tagline: 'Lindsay, Charlie, and your friends at Hawthorne',
        mailer_send_welcome_template_id: 'neqvygmmvz5g0p7w'
      }.freeze

    CONFIG.each do |key, value|
      define_singleton_method(('hawthorne_supply_co_' + key.to_s)) { value }
    end

    # -----------------------------------------------------------------------------

  end

end