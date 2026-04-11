# v3.0

module HawthorneCore::Site::HawthornePrintCo
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    #TODO: change contact_email, and mailer_send_welcome_template_id
    CONFIG =
      {
        env_name: HawthorneCore::AppConfig::HAWTHORNE_PRINT_CO_ENV_SITE_NAME,
        id: 2,
        name: 'Hawthorne Print Co',
        name_abbreviation: 'HPCO',
        site_sharing_scope: 'HAWTHORNE',
        has_checkout: true,
        contact_email: 'contact@hawthornesupplyco.com',
        email_from_tagline: 'Lindsay, Charlie, and your friends at Hawthorne',
        mailer_send_welcome_template_id: '0r83ql3v63xgzw1j'
      }.freeze

    CONFIG.each do |key, value|
      define_singleton_method(('hawthorne_print_co_' + key.to_s)) { value }
    end

    # -----------------------------------------------------------------------------

  end

end