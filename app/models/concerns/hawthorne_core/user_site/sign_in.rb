# v3.0

module HawthorneCore::UserSite::SignIn
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if a user exists for this site
    def self.user_exist?(user_id:) = exists?(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # -----------------------------------------------------------------------------

    # format the code, ex: '123456' formatted is '123-456'
    def sign_in_code_formatted = "#{sign_in_code[0, 3]}-#{sign_in_code[3, 3]}"

    # determine if the code is active - this is true when it is set, not expired, and the max number of attempts have not been reached
    def sign_in_code_active? = sign_in_code_set? && !sign_in_code_expired? && !sign_in_code_max_failed_attempts_reached?

    # determine if the code is set - this is true when the code is present, along with when it was created
    def sign_in_code_set? = sign_in_code.present? && sign_in_code_created_at.present?

    # determine if the code is expired
    def sign_in_code_expired? = sign_in_code_created_at.nil? || (sign_in_code_created_at < HawthorneCore::User::CODE_EXPIRATION_IN_MINUTES.minutes.ago)

    # determine if the max number of attempts have been reached
    def sign_in_code_max_failed_attempts_reached? = (sign_in_code_failed_attempts_count >= HawthorneCore::User::CODE_MAX_FAILED_ATTEMPTS_ALLOWED)

    # determine if the code matches
    def sign_in_code_match?(code:) = (sign_in_code == code.gsub(/\D/, ''))

    # ------------------------

    # clear the sign-in attributes
    def clear_sign_in_attrs
      update_columns(sign_in_code: nil, sign_in_code_created_at: nil, sign_in_code_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.sign_in_attrs_cleared
    end

    # ------------------------

    # set the sign-in attributes
    def set_sign_in_attrs
      attrs = { sign_in_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), sign_in_code_created_at: Time.current, sign_in_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.sign_in_attrs_set(user_id:, note: attrs)
    end

    # ------------------------

    # refresh the sign-in attributes
    def refresh_sign_in_attrs
      attrs = { sign_in_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), sign_in_code_created_at: Time.current, sign_in_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.sign_in_attrs_refreshed(user_id:, note: attrs)
      self
    end

    # refresh the sign-in attributes, then send it via specified delivery method (email / phone)
    def refresh_sign_in_attrs_then_send_it(delivery_method:, keep_signed_in:)
      refresh_sign_in_attrs
      HawthorneCore::Email::SendSignInCodeJob.perform_later(user_id:, keep_signed_in:) if (delivery_method == HawthorneCore::User::CODE_VIA_EMAIL)
      HawthorneCore::Text::SendSignInCodeJob.perform_later(user_id:) if (delivery_method == HawthorneCore::User::CODE_VIA_PHONE)
    end

    # ------------------------

    # increment the number of failed sign-in attempts with code
    def add_sign_in_code_failed_attempt = update_columns(sign_in_code_failed_attempts_count: (sign_in_code_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this sign-in code, was recently sent
    def sign_in_code_recently_sent_via_email?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id:,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'message_type' = ?", HawthorneCore::Services::MailerSendSvc::SIGN_IN_CODE).
        where("note->'personalization'->'data'->>'code' = ?", sign_in_code).
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # determine if a text message, with this sign-in code, was recently sent
    def sign_in_code_recently_sent_via_text_message?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id:,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:text_message_sent),
          success: true
        ).
        where("note->>'message_type' = ?", HawthorneCore::Services::TwilioTextSvc::SIGN_IN_CODE).
        where("note->>'message' LIKE ?", "%#{sign_in_code_formatted}%").
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end