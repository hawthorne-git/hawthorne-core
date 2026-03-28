# v3.0

module HawthorneCore::User::PinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    PIN_RANGE = 100_000..999_999.freeze

    PIN_EXPIRATION_IN_MINUTES = 10.freeze

    PIN_MAX_FAILED_ATTEMPTS_ALLOWED = 5.freeze

    PIN_RECENTLY_SENT_IN_SECONDS = 30.freeze

    PIN_VIA_EMAIL = 'EMAIL'.freeze

    PIN_VIA_PHONE = 'PHONE'.freeze

    PIN_DELIVERY_METHODS = [PIN_VIA_EMAIL, PIN_VIA_PHONE].freeze

    # -----------------------------------------------------------------------------

    def pin_default_delivery_via_email? = (pin_default_delivery == PIN_VIA_EMAIL)

    def pin_default_delivery_via_phone? = (pin_default_delivery == PIN_VIA_PHONE)

    # ----------------------------------------------------------------------------- SIGN IN

    def pin_active? = pin_set? && !pin_expired? && !pin_max_failed_attempts_reached?

    def pin_set? = pin.present? && pin_created_at.present?

    def pin_expired? = pin_created_at.nil? || (pin_created_at < PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def pin_max_failed_attempts_reached? = (pin_failed_attempts_count >= PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def pin_match?(pin_to_match) = (pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the users pin - log it
    def clear_pin
      update_columns(pin: nil, pin_created_at: nil, pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.pin_cleared(id)
    end

    # ------------------------

    # refresh the users pin - log it ... only do so if the pin is inactive
    def refresh_pin
      unless pin_active?
        update_columns(pin: SecureRandom.random_number(PIN_RANGE), pin_created_at: Time.current, pin_failed_attempts_count: 0)
        HawthorneCore::UserAction::Log.pin_created(id, { pin: pin })
      end
    end

    # refresh the users pin, then send it via email / phone
    def refresh_pin_then_send_it(delivery_method)
      refresh_pin
      HawthorneCore::Email::SendPinJob.perform_later(id) if (delivery_method == PIN_VIA_EMAIL)
      HawthorneCore::Text::SendPinJob.perform_later(id) if (delivery_method == PIN_VIA_PHONE)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_pin_failed_attempt = update_columns(pin_failed_attempts_count: (pin_failed_attempts_count.to_i + 1))

    # ----------------------------------------------------------------------------- EMAIL ADDRESS: UPDATE

    def email_address_update_pin_active? = email_address_update_pin_set? && !email_address_update_pin_expired? && !email_address_update_pin_max_failed_attempts_reached?

    def email_address_update_pin_set? = new_email_address_pin.present? && new_email_address_pin_created_at.present?

    def email_address_update_pin_expired? = new_email_address_pin_created_at.nil? || (new_email_address_pin_created_at < PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def email_address_update_pin_max_failed_attempts_reached? = (new_email_address_pin_failed_attempts_count >= PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def email_address_update_pin_match?(pin_to_match) = (new_email_address_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the email address update attributes - log it
    def clear_email_address_update_attrs
      update_columns(new_email_address: nil, new_email_address_pin: nil, new_email_address_pin_created_at: nil, new_email_address_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.email_address_update_attrs_cleared(id)
    end

    # ------------------------

    # set the email address update attributes - log it
    def set_email_address_update_attrs(new_email_address)
      attrs = { new_email_address: new_email_address, new_email_address_pin: SecureRandom.random_number(PIN_RANGE), new_email_address_pin_created_at: Time.current, new_email_address_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.email_address_update_attrs_set(id, attrs)
    end

    # ------------------------

    # refresh the users email address update pin, then send it via email
    def refresh_email_address_update_pin_then_send_it
      attrs = { new_email_address_pin: SecureRandom.random_number(PIN_RANGE), new_email_address_pin_created_at: Time.current, new_email_address_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.email_address_update_attrs_set(id, attrs)
      HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_email_address_update_pin_failed_attempt = update_columns(new_email_address_pin_failed_attempts_count: (new_email_address_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this email address update pin, was recently sent
    def email_address_update_pin_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin).
        where("note->'personalization'->'data'->>'pin' = ?", new_email_address_pin).
        where('created_at >= ?', PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # ----------------------------------------------------------------------------- UPDATE: PHONE NUMBER

    def phone_number_update_pin_active? = phone_number_update_pin_set? && !phone_number_update_pin_expired? && !phone_number_update_pin_max_failed_attempts_reached?

    def phone_number_update_pin_set? = new_phone_number_pin.present? && new_phone_number_pin_created_at.present?

    def phone_number_update_pin_expired? = new_phone_number_pin_created_at.nil? || (new_phone_number_pin_created_at < PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def phone_number_update_pin_max_failed_attempts_reached? = (new_phone_number_pin_failed_attempts_count >= PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def phone_number_update_pin_match?(pin_to_match) = (new_phone_number_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the phone number update attributes - log it
    def clear_phone_number_update_attrs
      update_columns(new_phone_number: nil, new_phone_number_pin: nil, new_phone_number_pin_created_at: nil, new_phone_number_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.phone_number_update_attrs_cleared(id)
    end

    # ------------------------

    # set the phone number attributes - log it
    def set_phone_number_update_attrs(new_phone_number)
      attrs = { new_phone_number: new_phone_number, new_phone_number_pin: SecureRandom.random_number(PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.phone_number_update_attrs_set(id, attrs)
    end

    # ------------------------

    # refresh the users phone number update pin, then send it via text message
    def refresh_phone_number_update_pin_then_send_it
      attrs = { new_phone_number_pin: SecureRandom.random_number(PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.phone_number_update_attrs_set(id, attrs)
      #HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_phone_number_update_pin_failed_attempt = update_columns(new_phone_number_pin_failed_attempts_count: (new_phone_number_pin_failed_attempts_count.to_i + 1))

    # ------------------------
    #
    # -----------------------------------------------------------------------------

  end

end