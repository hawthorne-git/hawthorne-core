# v3.0

module HawthorneCore::User::SignInOut
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # define the allowed sign-in code delivery methods
    def self.sign_in_code_delivery_methods = [HawthorneCore::User::CODE_VIA_EMAIL, HawthorneCore::User::CODE_VIA_PHONE]

    # define the labels for each sign-in code delivery methods
    def sign_in_code_delivery_labels = { HawthorneCore::User::CODE_VIA_EMAIL => 'Email', HawthorneCore::User::CODE_VIA_PHONE => 'Text Message' }

    # -----------------------------------------------------------------------------

    # find the sign in code default delivery label
    def sign_in_code_default_delivery_pretty_print = sign_in_code_delivery_labels[sign_in_code_default_delivery]

    # updates a users sign-in code default delivery method
    def update_sign_in_code_default_delivery(sign_in_code_default_delivery:)
      update(sign_in_code_default_delivery:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_code_default_delivery: sign_in_code_default_delivery_before_last_save, sign_in_code_default_delivery: })
    end

    # -----------------------------------------------------------------------------

    # clear the users sign-in attributes
    def clear_sign_in_attrs = user_site.clear_sign_in_attrs

    # set the users sign-in attributes
    def set_sign_in_attrs = user_site.set_sign_in_attrs

    # -----------------------------------------------------------------------------

    # sign-in the user
    def sign_in(user_session_token:, keep_signed_in:)

      # log the sign-in and clear the sign-in attributes
      HawthorneCore::UserAction::Log.sign_in(user_id:)
      clear_sign_in_attrs

      # verify the users email, if not done prior
      update_columns(email_verified: true) unless email_verified?

      # attach the user to their session
      HawthorneCore::UserSession.find_by(token: user_session_token)&.update_columns(user_id:)

      # determine if this is the users first sign-in on this site
      first_sign_in_on_site =  HawthorneCore::UserSite.first_sign_in?(user_id:)

      # capture the users site sign-in ...
      # this is a record for each user / site that captures the users first sign-in, last sign-in, #sign-ins, and if they should be kept as signed in
      HawthorneCore::UserSite.sign_in(user_id:, keep_signed_in:)

      # create the user a stripe customer account, if not done prior
      HawthorneCore::Stripe::CreateCustomerJob.perform_later(user_id:) unless stripe_customer?

      # if this is the users first sign-in (on site) ... send the user a welcome email
      HawthorneCore::Email::SendWelcomeEmailJob.perform_later(user_id:) if first_sign_in_on_site

    end
    def self.sign_in(user_id:, user_session_token:, keep_signed_in:) = find_by(user_id:).sign_in(user_session_token:, keep_signed_in:)

    # -----------------------------------------------------------------------------

    # sign-out the user
    # as the user is forcing a sign-out - remove ability to keep signed in via cookie
    def self.sign_out(user_id:)
      HawthorneCore::UserSite.sign_out(user_id:)
      HawthorneCore::UserAction::Log.sign_out(user_id:)
    end

    # -----------------------------------------------------------------------------

  end

end