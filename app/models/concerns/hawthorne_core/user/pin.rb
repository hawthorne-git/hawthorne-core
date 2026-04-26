# v3.0

module HawthorneCore::User::Pin
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    PIN_RANGE = 100_000..999_999.freeze

    PIN_EXPIRATION_IN_MINUTES = 10.freeze

    PIN_MAX_FAILED_ATTEMPTS_ALLOWED = 5.freeze

    PIN_RECENTLY_SENT_IN_SECONDS = 30.freeze

    PIN_VIA_EMAIL = 'EMAIL'.freeze

    PIN_VIA_PHONE = 'PHONE'.freeze

    # ------------------------

    SIGN_IN_PIN_DELIVERY_METHODS = [PIN_VIA_EMAIL, PIN_VIA_PHONE].freeze

    # -----------------------------------------------------------------------------

    def sign_in_pin_default_delivery_via_email? = (sign_in_pin_default_delivery == PIN_VIA_EMAIL)

    def sign_in_pin_default_delivery_via_phone? = (sign_in_pin_default_delivery == PIN_VIA_PHONE)

    # -----------------------------------------------------------------------------

    # get the sign in pin default delivery, in a prettier format then what is saved in the database
    def sign_in_pin_default_delivery_pretty_print
      return 'Email' if sign_in_pin_default_delivery_via_email?
      return 'Text Message' if sign_in_pin_default_delivery_via_phone?
      nil
    end

    # -----------------------------------------------------------------------------

    # updates a users full name
    def update_sign_in_pin_default_delivery(sign_in_pin_default_delivery:)
      update(sign_in_pin_default_delivery: sign_in_pin_default_delivery)
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_pin_default_delivery: sign_in_pin_default_delivery_before_last_save, new_sign_in_pin_default_delivery: sign_in_pin_default_delivery })
    end

    # -----------------------------------------------------------------------------

  end

end