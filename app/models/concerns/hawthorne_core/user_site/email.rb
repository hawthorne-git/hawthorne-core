# v3.0

module HawthorneCore::UserSite::Email
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # format the code, ex: '123456' formatted is '123-456'
    def new_email_code_formatted = "#{new_email_code[0, 3]}-#{new_email_code[3, 3]}"

    # determine if the code is active - this is true when it is set, not expired, and the max number of attempts have not been reached
    def new_email_code_active? = new_email_code_set? && !new_email_code_expired? && !new_email_code_max_failed_attempts_reached?

    # determine if the code is set - this is true when the code is present, along with when it was created
    def new_email_code_set? = new_email_code.present? && new_email_code_created_at.present?

    # determine if the code is expired
    def new_email_code_expired? = new_email_code_created_at.nil? || (new_email_code_created_at < HawthorneCore::User::CODE_EXPIRATION_IN_MINUTES.minutes.ago)

    # determine if the max number of attempts have been reached
    def new_email_code_max_failed_attempts_reached? = (new_email_code_failed_attempts_count >= HawthorneCore::User::CODE_MAX_FAILED_ATTEMPTS_ALLOWED)

    # determine if the code matches
    def new_email_code_match?(code:) = (new_email_code == code.gsub(/\D/, ''))

    # ------------------------

    # clear the new email attributes
    def clear_new_email_attrs
      update_columns(new_email: nil, new_email_code: nil, new_email_code_created_at: nil, new_email_code_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.new_email_attrs_cleared
    end

    # ------------------------

    # set the new email attributes
    def set_new_email_attrs(new_email:)
      attrs = { new_email:, new_email_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), new_email_code_created_at: Time.current, new_email_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_email_attrs_set(note: attrs)
    end

    # ------------------------

    # refresh the new email attributes
    def refresh_new_email_attrs
      attrs = { new_email_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), new_email_code_created_at: Time.current, new_email_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.new_email_attrs_refreshed(user_id:, note: attrs)
      self
    end

    # refresh the new email attributes, then send it via email
    def refresh_new_email_attrs_then_send_it
      refresh_new_email_attrs
      HawthorneCore::Email::SendEmailUpdateCodeJob.perform_later(user_id:)
    end

    # ------------------------

    # increment the number of failed attempts with code
    def add_new_email_code_failed_attempt = update_columns(new_email_code_failed_attempts_count: (new_email_code_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this new email code, was recently sent
    def new_email_code_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id:,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'message_type' = ?", HawthorneCore::Services::MailerSendSvc::EMAIL_UPDATE_CODE).
        where("note->'personalization'->'data'->>'code' = ?", new_email_code).
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end