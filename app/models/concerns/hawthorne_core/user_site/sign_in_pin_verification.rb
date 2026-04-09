# v3.0

module HawthorneCore::UserSite::SignInPinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def sign_in_pin_formatted = "#{sign_in_pin[0,3]}-#{sign_in_pin[3,3]}"

    def sign_in_pin_active? = sign_in_pin_set? && !sign_in_pin_expired? && !sign_in_pin_max_failed_attempts_reached?

    def sign_in_pin_set? = sign_in_pin.present? && sign_in_pin_created_at.present?

    def sign_in_pin_expired? = sign_in_pin_created_at.nil? || (sign_in_pin_created_at < HawthorneCore::User::PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def sign_in_pin_max_failed_attempts_reached? = (sign_in_pin_failed_attempts_count >= HawthorneCore::User::PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def sign_in_pin_match?(pin_to_match) = (sign_in_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the users sign-in pin - log it
    def clear_sign_in_pin
      update_columns(sign_in_pin: nil, sign_in_pin_created_at: nil, sign_in_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.sign_in_pin_cleared(user_id)
    end

    # ------------------------

    # refresh the users sign-in pin (for site) - log it ... only do so if the pin is inactive
    def refresh_sign_in_pin
      unless sign_in_pin_active?
        update_columns(sign_in_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), sign_in_pin_created_at: Time.current, sign_in_pin_failed_attempts_count: 0)
        HawthorneCore::UserAction::Log.sign_in_pin_created(user_id, { sign_in_pin: sign_in_pin })
      end
    end

    # refresh the users pin, then send it via the specified delivery method (email / phone)
    def refresh_sign_in_pin_then_send_it(delivery_method, keep_signed_in)
      refresh_sign_in_pin
      HawthorneCore::Email::SendSignInPinJob.perform_later(user_id, keep_signed_in) if (delivery_method == HawthorneCore::User::PIN_VIA_EMAIL)
      HawthorneCore::Text::SendSignInPinJob.perform_later(user_id) if (delivery_method == HawthorneCore::User::PIN_VIA_PHONE)
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
        where('created_at >= ?', HawthorneCore::User::PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
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
        where('created_at >= ?', HawthorneCore::User::PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end