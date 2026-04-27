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
      HawthorneCore::UserAction::Log.email_verified(note: { email: })
    end

    # -----------------------------------------------------------------------------

    # clear the users new email attributes, which is site specific
    def clear_new_email_attrs = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id:, site_id: HawthorneCore::Site.this_site_id).clear_new_email_attrs

    # set the users new email attributes, which is site specific
    def set_new_email_attrs(email:) = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id:, site_id: HawthorneCore::Site.this_site_id).set_new_email_attrs(new_email: email)

    # -----------------------------------------------------------------------------

    # updates a users email,
    # clear their new email attributes
    # then update the users email, within stripe
    def update_email(email:)
      update(email:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_email: email_before_last_save, email: })
      clear_new_email_attrs
      HawthorneCore::Stripe::UpdateCustomerEmailJob.perform_later(user_id:)
    end

    # -----------------------------------------------------------------------------

  end

end