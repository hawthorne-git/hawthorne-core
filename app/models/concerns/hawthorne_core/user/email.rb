# v3.0

module HawthorneCore::User::Email
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # get the email for a user id
    def self.email(user_id:) = where(user_id:).pick(:email)

    # -----------------------------------------------------------------------------

    # determine if an email is verified
    def email_verified? = email_verified

    # -----------------------------------------------------------------------------

    # clear the users new email attributes, which is site specific
    def clear_new_email_attrs = user_site.clear_new_email_attrs
    def self.clear_new_email_attrs(user_id:) = user_site(user_id:).clear_new_email_attrs

    # set the users new email attributes, which is site specific, then send the code via email
    def self.set_new_email_attrs_then_send_it(user_id:, email:) = user_site(user_id:).set_new_email_attrs_then_send_it(new_email: email)

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
    def self.update_email(user_id:, email:) = find_by(user_id:).update_email(email:)

    # -----------------------------------------------------------------------------

  end

end