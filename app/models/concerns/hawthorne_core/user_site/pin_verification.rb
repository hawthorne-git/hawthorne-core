# v3.0

module HawthorneCore::UserSite::PinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    PIN_RANGE = 100_000..999_999.freeze

    PIN_EXPIRATION_IN_MINUTES = 10.freeze

    PIN_MAX_FAILED_ATTEMPTS_ALLOWED = 5.freeze

    PIN_RECENTLY_SENT_IN_SECONDS = 30.freeze

    # ----------------------------------------------------------------------------- SIGN IN

    def sign_in_pin_formatted = "#{sign_in_pin[0,3]}-#{sign_in_pin[3,3]}"

    def sign_in_pin_active? = sign_in_pin_set? && !sign_in_pin_expired? && !sign_in_pin_max_failed_attempts_reached?

    def sign_in_pin_set? = sign_in_pin.present? && sign_in_pin_created_at.present?

    def sign_in_pin_expired? = sign_in_pin_created_at.nil? || (sign_in_pin_created_at < PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def sign_in_pin_max_failed_attempts_reached? = (sign_in_pin_failed_attempts_count >= PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def sign_in_pin_match?(pin_to_match) = (sign_in_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the users sign-in pin - log it
    def clear_sign_in_pin?
      update_columns(sign_in_pin: nil, sign_in_pin_created_at: nil, sign_in_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.sign_in_pin_cleared(user_id)
    end

    # ------------------------

    # refresh the users sign-in pin (for site) - log it ... only do so if the pin is inactive
    def refresh_sign_in_pin
      unless sign_in_pin_active?
        update_columns(sign_in_pin: SecureRandom.random_number(PIN_RANGE), sign_in_pin_created_at: Time.current, sign_in_pin_failed_attempts_count: 0)
        HawthorneCore::UserAction::Log.sign_in_pin_created(user_id, { sign_in_pin: sign_in_pin })
      end
    end

    # refresh the users pin, then send it via the specified delivery method (email / phone)
    def refresh_sign_in_pin_then_send_it(delivery_method)
      refresh_sign_in_pin
      HawthorneCore::Email::SendSignInPinJob.perform_later(user_id) if (delivery_method == HawthorneCore::User::PinVerification::PIN_VIA_EMAIL)
      HawthorneCore::Text::SendSignInPinJob.perform_later(user_id) if (delivery_method == HawthorneCore::User::PinVerification::PIN_VIA_PHONE)
    end

    # ------------------------

    # increment the number of failed sign-in attempts with pin
    def add_sign_in_pin_failed_attempt = update_columns(sign_in_pin_failed_attempts_count: (sign_in_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this sign-in pin, was recently sent
    def sign_in_pin_recently_sent_via_email?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: user_id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc::SIGN_IN_VERIFICATION_PIN).
        where("note->'personalization'->'data'->>'pin' = ?", sign_in_pin).
        where('created_at >= ?', PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # determine if a text message, with this sign-in pin, was recently sent
    def sign_in_pin_recently_sent_via_text_message?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: user_id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:text_message_sent),
          success: true
        ).
        where("note->>'text_message_type' = ?", HawthorneCore::Services::TwilioTextSvc::SIGN_IN_VERIFICATION_PIN).
        where("note->>'message' LIKE ?", "%#{sign_in_pin}%").
        where('created_at >= ?', PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # ----------------------------------------------------------------------------- EMAIL ADDRESS: UPDATE

    def new_email_address_pin_formatted = "#{new_email_address_pin[0,3]}-#{new_email_address_pin[3,3]}"

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

    # refresh the users email address update pin / pin created at / failed attempts ... only do so if the pin is inactive
    def refresh_email_address_update_pin_attrs
      unless email_address_update_pin_active?
        attrs = { new_email_address_pin: SecureRandom.random_number(PIN_RANGE), new_email_address_pin_created_at: Time.current, new_email_address_pin_failed_attempts_count: 0 }
        update_columns(attrs)
        HawthorneCore::UserAction::Log.email_address_update_attrs_refreshed(id, attrs)
      end
    end

    # refresh the users email address update pin attributes, then send it via email
    def refresh_email_address_update_pin_attrs_then_send_it
      refresh_email_address_update_pin_attrs
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
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc::EMAIL_ADDRESS_UPDATE_VERIFICATION_PIN).
        where("note->'personalization'->'data'->>'pin' = ?", new_email_address_pin).
        where('created_at >= ?', PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # ----------------------------------------------------------------------------- UPDATE: PHONE NUMBER

    def new_phone_number_pin_formatted = "#{new_phone_number_pin[0,3]}-#{new_phone_number_pin[3,3]}"

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
      attrs = { new_phone_number: Phonelib.parse(new_phone_number, 'US').e164, new_phone_number_pin: SecureRandom.random_number(PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.phone_number_update_attrs_set(id, attrs)
    end

    # ------------------------

    # refresh the users phone number update pin / pin created at / failed attempts
    def refresh_phone_number_update_pin_attrs
      unless phone_number_update_pin_active?
        attrs = { new_phone_number_pin: SecureRandom.random_number(PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
        update_columns(attrs)
        HawthorneCore::UserAction::Log.phone_number_update_attrs_refreshed(id, attrs)
      end
    end

    # refresh the users phone number update pin attributes, then send it via text message
    def refresh_phone_number_update_pin_attrs_then_send_it
      refresh_phone_number_update_pin_attrs
      HawthorneCore::Text::SendPhoneNumberUpdatePinJob.perform_later(id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_phone_number_update_pin_failed_attempt = update_columns(new_phone_number_pin_failed_attempts_count: (new_phone_number_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if a text message, with this phone number update pin, was recently sent
    def phone_number_update_pin_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:text_message_sent),
          success: true
        ).
        where("note->>'text_message_type' = ?", HawthorneCore::Services::TwilioTextSvc::PHONE_NUMBER_UPDATE_VERIFICATION_PIN).
        where("note->>'message' LIKE ?", "%#{new_phone_number_pin_formatted}%").
        where('created_at >= ?', PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end