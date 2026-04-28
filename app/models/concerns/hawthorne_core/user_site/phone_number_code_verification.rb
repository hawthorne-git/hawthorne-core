# v3.0

module HawthorneCore::UserSite::PhoneNumberCodeVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def new_phone_number_code_formatted = "#{new_phone_number_code[0, 3]}-#{new_phone_number_code[3, 3]}"

    def new_phone_number_code_active? = new_phone_number_code_set? && !new_phone_number_code_expired? && !new_phone_number_code_max_failed_attempts_reached?

    def new_phone_number_code_set? = new_phone_number_code.present? && new_phone_number_code_created_at.present?

    def new_phone_number_code_expired? = new_phone_number_code_created_at.nil? || (new_phone_number_code_created_at < HawthorneCore::User::CODE_EXPIRATION_IN_MINUTES.minutes.ago)

    def new_phone_number_code_max_failed_attempts_reached? = (new_phone_number_code_failed_attempts_count >= HawthorneCore::User::CODE_MAX_FAILED_ATTEMPTS_ALLOWED)

    def new_phone_number_code_match?(code_to_match:) = (new_phone_number_code == code_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the new phone number attributes
    def clear_new_phone_number_attrs
      update_columns(new_phone_number: nil, new_phone_number_code: nil, new_phone_number_code_created_at: nil, new_phone_number_code_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.new_phone_number_attrs_cleared
    end

    # ------------------------

    # set the new phone number attributes
    def set_new_phone_number_attrs(new_phone_number:)
      attrs = { new_phone_number: Phonelib.parse(new_phone_number, 'US').e164, new_phone_number_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), new_phone_number_code_created_at: Time.current, new_phone_number_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_phone_number_attrs_set(note: attrs)
    end

    # ------------------------

    # refresh the users new phone number code / code created at / failed attempts
    def refresh_new_phone_number_code_attrs
      attrs = { new_phone_number_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), new_phone_number_code_created_at: Time.current, new_phone_number_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_phone_number_attrs_refreshed(user_id:, note: attrs)
      self
    end

    # refresh the users new phone number code attributes, then send it via text message
    def refresh_new_phone_number_code_attrs_then_send_it
      refresh_new_phone_number_code_attrs
      HawthorneCore::Text::SendPhoneNumberUpdateCodeJob.perform_later(user_id:)
    end

    # ------------------------

    # increment the number of failed attempts with code
    def add_new_phone_number_code_failed_attempt = update_columns(new_phone_number_code_failed_attempts_count: (new_phone_number_code_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if a text message, with this new phone number code, was recently sent
    def new_phone_number_code_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id:,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:text_message_sent),
          success: true
        ).
        where("note->>'text_message_type' = ?", HawthorneCore::Services::TwilioTextSvc::PHONE_NUMBER_UPDATE_CODE).
        where("note->>'message' LIKE ?", "%#{new_phone_number_code_formatted}%").
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end