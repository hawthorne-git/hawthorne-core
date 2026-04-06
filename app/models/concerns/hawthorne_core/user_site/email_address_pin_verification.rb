# v3.0

module HawthorneCore::UserSite::EmailAddressPinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def new_email_address_pin_formatted = "#{new_email_address_pin[0,3]}-#{new_email_address_pin[3,3]}"

    def new_email_address_pin_active? = new_email_address_pin_set? && !new_email_address_pin_expired? && !new_email_address_pin_max_failed_attempts_reached?

    def new_email_address_pin_set? = new_email_address_pin.present? && new_email_address_pin_created_at.present?

    def new_email_address_pin_expired? = new_email_address_pin_created_at.nil? || (new_email_address_pin_created_at < HawthorneCore::User::PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def new_email_address_pin_max_failed_attempts_reached? = (new_email_address_pin_failed_attempts_count >= HawthorneCore::User::PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def new_email_address_pin_match?(pin_to_match) = (new_email_address_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the new phone number attributes - log it
    def clear_new_email_address_attrs
      update_columns(new_email_address: nil, new_email_address_pin: nil, new_email_address_pin_created_at: nil, new_email_address_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.new_email_address_attrs_cleared(user_id)
    end

    # ------------------------

    # set the new phone number attributes - log it
    def set_new_email_address_attrs(new_email_address)
      attrs = { new_email_address: new_email_address, new_email_address_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), new_email_address_pin_created_at: Time.current, new_email_address_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_email_address_attrs_set(user_id, attrs)
    end

    # ------------------------

    # refresh the users new phone number pin / pin created at / failed attempts
    def refresh_new_email_address_pin_attrs
      unless new_email_address_pin_active?
        attrs = { new_email_address_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), new_email_address_pin_created_at: Time.current, new_email_address_pin_failed_attempts_count: 0 }
        update_columns(attrs)
        HawthorneCore::UserAction::Log.new_email_address_attrs_refreshed(user_id, attrs)
      end
    end

    # refresh the users new phone number pin attributes, then send it via text message
    def refresh_new_email_address_pin_attrs_then_send_it
      refresh_new_email_address_pin_attrs
      HawthorneCore::Text::SendPhoneNumberUpdatePinJob.perform_later(user_id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_new_email_address_pin_failed_attempt = update_columns(new_email_address_pin_failed_attempts_count: (new_email_address_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this new email address pin, was recently sent
    def new_email_address_pin_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: user_id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc::EMAIL_ADDRESS_UPDATE_VERIFICATION_PIN).
        where("note->'personalization'->'data'->>'pin' = ?", new_email_address_pin).
        where('created_at >= ?', HawthorneCore::User::PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end