# v3.0

module HawthorneCore::UserSite::SignInCodeVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def sign_in_code_formatted = "#{sign_in_code[0,3]}-#{sign_in_code[3,3]}"

    def sign_in_code_active? = sign_in_code_set? && !sign_in_code_expired? && !sign_in_code_max_failed_attempts_reached?

    def sign_in_code_set? = sign_in_code.present? && sign_in_code_created_at.present?

    def sign_in_code_expired? = sign_in_code_created_at.nil? || (sign_in_code_created_at < HawthorneCore::User::CODE_EXPIRATION_IN_MINUTES.minutes.ago)

    def sign_in_code_max_failed_attempts_reached? = (sign_in_code_failed_attempts_count >= HawthorneCore::User::CODE_MAX_FAILED_ATTEMPTS_ALLOWED)

    def sign_in_code_match?(code_to_match) = (sign_in_code == code_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the users sign-in code - log it
    def clear_sign_in_code
      update_columns(sign_in_code: nil, sign_in_code_created_at: nil, sign_in_code_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.sign_in_code_cleared(user_id)
    end

    # ------------------------

    # refresh the users sign-in code (for site) - log it ... only do so if the code is inactive
    def refresh_sign_in_code
      unless sign_in_code_active?
        update_columns(sign_in_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), sign_in_code_created_at: Time.current, sign_in_code_failed_attempts_count: 0)
        HawthorneCore::UserAction::Log.sign_in_code_created(user_id, { sign_in_code: sign_in_code })
      end
    end

    # refresh the users code, then send it via the specified delivery method (email / phone)
    def refresh_sign_in_code_then_send_it(delivery_method, keep_signed_in)
      refresh_sign_in_code
      HawthorneCore::Email::SendSignInCodeJob.perform_later(user_id, keep_signed_in) if (delivery_method == HawthorneCore::User::CODE_VIA_EMAIL)
      HawthorneCore::Text::SendSignInCodeJob.perform_later(user_id) if (delivery_method == HawthorneCore::User::CODE_VIA_PHONE)
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
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc::SIGN_IN_CODE).
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
        where("note->>'text_message_type' = ?", HawthorneCore::Services::TwilioTextSvc::SIGN_IN_CODE).
        where("note->>'message' LIKE ?", "%#{sign_in_code}%").
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end