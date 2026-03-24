# v3.0XXX

module HawthorneCore::User::SingleSignOn
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has ONLY signed-in via sso
    # this is true when there does not exist ANY traditional successful sign-ins
    def only_sign_in_via_sso?(email_address)
      HawthorneCore::UserAction.
        where(site_user_id: site_user_id).
        where(action: HawthorneCore::UserAction::Action.sign_in).
        where(success: true).
        count.zero?
    end

    # -----------------------------------------------------------------------------

  end

end