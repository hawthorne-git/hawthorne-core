# v3.0

module HawthorneCore::UserSite::PhoneNumberPinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def new_phone_number_pin_formatted = "#{new_phone_number_pin[0,3]}-#{new_phone_number_pin[3,3]}"

    def new_phone_number_pin_active? = new_phone_number_pin_set? && !new_phone_number_pin_expired? && !new_phone_number_pin_max_failed_attempts_reached?

    def new_phone_number_pin_set? = new_phone_number_pin.present? && new_phone_number_pin_created_at.present?

    def new_phone_number_pin_expired? = new_phone_number_pin_created_at.nil? || (new_phone_number_pin_created_at < HawthorneCore::User::PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def new_phone_number_pin_max_failed_attempts_reached? = (new_phone_number_pin_failed_attempts_count >= HawthorneCore::User::PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def new_phone_number_pin_match?(pin_to_match) = (new_phone_number_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the new phone number attributes - log it
    def clear_new_phone_number_attrs
      update_columns(new_phone_number: nil, new_phone_number_pin: nil, new_phone_number_pin_created_at: nil, new_phone_number_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.new_phone_number_attrs_cleared(user_id)
    end

    # ------------------------

    # set the new phone number attributes - log it
    def set_new_phone_number_attrs(new_phone_number)
      attrs = { new_phone_number: Phonelib.parse(new_phone_number, 'US').e164, new_phone_number_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_phone_number_attrs_set(user_id, attrs)
    end

    # ------------------------

    # refresh the users new phone number pin / pin created at / failed attempts
    def refresh_new_phone_number_pin_attrs
      unless new_phone_number_pin_active?
        attrs = { new_phone_number_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), new_phone_number_pin_created_at: Time.current, new_phone_number_pin_failed_attempts_count: 0 }
        update_columns(attrs)
        HawthorneCore::UserAction::Log.new_phone_number_attrs_refreshed(user_id, attrs)
      end
    end

    # refresh the users new phone number pin attributes, then send it via text message
    def refresh_new_phone_number_pin_attrs_then_send_it
      refresh_new_phone_number_pin_attrs
      HawthorneCore::Text::SendPhoneNumberUpdatePinJob.perform_later(user_id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_new_phone_number_pin_failed_attempt = update_columns(new_phone_number_pin_failed_attempts_count: (new_phone_number_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if a text message, with this new phone number pin, was recently sent
    def new_phone_number_pin_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: user_id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:text_message_sent),
          success: true
        ).
        where("note->>'text_message_type' = ?", HawthorneCore::Services::TwilioTextSvc::PHONE_NUMBER_UPDATE_VERIFICATION_PIN).
        where("note->>'message' LIKE ?", "%#{new_phone_number_pin_formatted}%").
        where('created_at >= ?', HawthorneCore::User::PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end