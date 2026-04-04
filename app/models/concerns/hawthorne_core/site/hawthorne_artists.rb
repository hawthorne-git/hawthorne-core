# v3.0

module HawthorneCore::Site::HawthorneArtists
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    #TODO: change id, contact_email, and mailer_send_welcome_template_id
    CONFIG =
      {
        env_name: HawthorneCore::AppConfig::HAWTHORNE_ARTISTS_ENV_SITE_NAME,
        id: 1,
        name: 'Hawthorne Artists',
        site_sharing_scope: 'HAWTHORNE',
        has_checkout: false,
        contact_email: 'contact@hawthornesupplyco.com',
        email_from_tagline: 'Lindsay, Charlie, and your friends at Hawthorne',
        mailer_send_welcome_template_id: 'neqvygmmvz5g0p7w'
      }.freeze

    CONFIG.each do |key, value|
      define_singleton_method(('hawthorne_artists_' + key.to_s)) { value }
    end

    # -----------------------------------------------------------------------------

  end

end