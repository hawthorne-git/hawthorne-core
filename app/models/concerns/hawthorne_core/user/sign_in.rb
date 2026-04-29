# v3.0

module HawthorneCore::User::SignIn
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # define the allowed sign-in code delivery methods
    def self.sign_in_code_delivery_methods = [HawthorneCore::User::CODE_VIA_EMAIL, HawthorneCore::User::CODE_VIA_PHONE]

    # define the labels for each sign-in code delivery methods
    def self.sign_in_code_delivery_labels = { HawthorneCore::User::CODE_VIA_EMAIL => 'Email', HawthorneCore::User::CODE_VIA_PHONE => 'Text Message' }

    # -----------------------------------------------------------------------------

    # determine if the sign-in code default delivery is via email
    def sign_in_code_default_delivery_via_email? = (sign_in_code_default_delivery == HawthorneCore::User::CODE_VIA_EMAIL)

    # determine if the sign-in code default delivery is via text message
    def sign_in_code_default_delivery_via_phone? = (sign_in_code_default_delivery == HawthorneCore::User::CODE_VIA_PHONE)

    # get the sign in code default delivery, in a prettier format then what is saved in the database
    def sign_in_code_default_delivery_pretty_print = sign_in_code_delivery_labels[sign_in_code_default_delivery]

    # -----------------------------------------------------------------------------

    # updates a users sign-in code default delivery method
    def update_sign_in_code_default_delivery(sign_in_code_default_delivery:)
      update(sign_in_code_default_delivery:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_code_default_delivery: sign_in_code_default_delivery_before_last_save, sign_in_code_default_delivery: })
    end

    # -----------------------------------------------------------------------------

    # clear the users sign-in attributes, which is site specific
    def clear_sign_in_attrs = user_site.clear_sign_in_attrs

    # set the users sign-in attributes, which is site specific
    def set_sign_in_attrs = user_site.set_sign_in_attrs

    # -----------------------------------------------------------------------------

    #TODO:
    def log_site_sign_in(keep_signed_in:) = HawthorneCore::UserSite.log_site_sign_in(user_id:, keep_signed_in:)

    # -----------------------------------------------------------------------------

  end

end