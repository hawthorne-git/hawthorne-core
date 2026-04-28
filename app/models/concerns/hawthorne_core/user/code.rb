# v3.0

module HawthorneCore::User::Code
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    CODE_RANGE = (100_000..999_999).freeze

    CODE_EXPIRATION_IN_MINUTES = 10

    CODE_MAX_FAILED_ATTEMPTS_ALLOWED = 5

    CODE_RECENTLY_SENT_IN_SECONDS = 30

    CODE_VIA_EMAIL = 'EMAIL'.freeze

    CODE_VIA_PHONE = 'PHONE'.freeze

    # ------------------------

    SIGN_IN_CODE_DELIVERY_METHODS = [CODE_VIA_EMAIL, CODE_VIA_PHONE].freeze

    SIGN_IN_CODE_DELIVERY_LABELS = { CODE_VIA_EMAIL => 'Email', CODE_VIA_PHONE => 'Text Message' }.freeze

    # -----------------------------------------------------------------------------

    # determine if the sign-in code default delivery is via email
    def sign_in_code_default_delivery_via_email? = (sign_in_code_default_delivery == CODE_VIA_EMAIL)

    # determine if the sign-in code default delivery is via text message
    def sign_in_code_default_delivery_via_phone? = (sign_in_code_default_delivery == CODE_VIA_PHONE)

    # get the sign in code default delivery, in a prettier format then what is saved in the database
    def sign_in_code_default_delivery_pretty_print = SIGN_IN_CODE_DELIVERY_LABELS[sign_in_code_default_delivery]

    # -----------------------------------------------------------------------------

    # updates a users sign-in code default delivery method
    def update_sign_in_code_default_delivery(sign_in_code_default_delivery:)
      update(sign_in_code_default_delivery:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_code_default_delivery: sign_in_code_default_delivery_before_last_save, sign_in_code_default_delivery: })
    end

    # -----------------------------------------------------------------------------

  end

end