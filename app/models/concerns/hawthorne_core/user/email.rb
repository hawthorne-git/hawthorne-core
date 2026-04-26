# v3.0

module HawthorneCore::User::Email
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if an email is verified
    def email_verified? = email_verified

    # verify a users email, if not previously verified
    def verify_email
      return if email_verified?
      update_columns(email_verified: true)
      HawthorneCore::UserAction::Log.email_verified(note: { email: email })
    end

    # -----------------------------------------------------------------------------

    # clear the users new email attributes, which is site specific
    def clear_new_email_attrs = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id: id, site_id: HawthorneCore::Site.this_site_id).clear_new_email_attrs

    # set the users new email attributes, which is site specific
    def set_new_email_attrs(new_email:) = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id: id, site_id: HawthorneCore::Site.this_site_id).set_new_email_attrs(new_email:)

    # -----------------------------------------------------------------------------

  end

end