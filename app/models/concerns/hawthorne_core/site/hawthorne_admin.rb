# v3.0

module HawthorneCore::Site::HawthorneAdmin
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    #TODO: change id, contact_email, and mailer_send_welcome_template_id
    CONFIG =
      {
        env_name: HawthorneCore::AppConfig::HAWTHORNE_ADMIN_ENV_SITE_NAME,
        id: 1,
        name: 'Hawthorne Admin',
        site_sharing_scope: 'HAWTHORNE',
        has_checkout: false
      }.freeze

    CONFIG.each do |key, value|
      define_singleton_method(('hawthorne_admin_' + key.to_s)) { value }
    end

    # -----------------------------------------------------------------------------

  end

end