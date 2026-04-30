# v3.0

module HawthorneCore::UserSite::DeleteAccount
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # format the code, ex: '123456' formatted is '123-456'
    def delete_account_code_formatted = "#{delete_account_code[0, 3]}-#{delete_account_code[3, 3]}"

    # determine if the code is active - this is true when it is set, not expired, and the max number of attempts have not been reached
    def delete_account_code_active? = delete_account_code_set? && !delete_account_code_expired? && !delete_account_code_max_failed_attempts_reached?

    # determine if the code is set - this is true when the code is present, along with when it was created
    def delete_account_code_set? = delete_account_code.present? && delete_account_code_created_at.present?

    # determine if the code is expired
    def delete_account_code_expired? = delete_account_code_created_at.nil? || (delete_account_code_created_at < HawthorneCore::User::CODE_EXPIRATION_IN_MINUTES.minutes.ago)

    # determine if the max number of attempts have been reached
    def delete_account_code_max_failed_attempts_reached? = (delete_account_code_failed_attempts_count >= HawthorneCore::User::CODE_MAX_FAILED_ATTEMPTS_ALLOWED)

    # determine if the code matches
    def delete_account_code_match?(code:) = (delete_account_code == code.gsub(/\D/, ''))

    # ------------------------

    # clear the delete account attributes
    def clear_delete_account_attrs
      update_columns(delete_account_code: nil, delete_account_code_created_at: nil, delete_account_code_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.delete_account_attrs_cleared
    end

    # ------------------------

    # set the delete account attributes
    def set_delete_account_attrs
      attrs = { delete_account_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), delete_account_code_created_at: Time.current, delete_account_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.delete_account_attrs_set(note: attrs)
    end

    # ------------------------

    # refresh the delete account attributes
    def refresh_delete_account_attrs
      attrs = { delete_account_code: SecureRandom.random_number(HawthorneCore::User::CODE_RANGE), delete_account_code_created_at: Time.current, delete_account_code_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.delete_account_attrs_refreshed(user_id:, note: attrs)
      self
    end

    # refresh the delete account attributes, then send it via email
    def refresh_delete_account_attrs_then_send_it
      refresh_delete_account_attrs
      HawthorneCore::Email::SendDeleteAccountCodeJob.perform_later(user_id:)
    end

    # ------------------------

    # increment the number of failed attempts with code
    def add_delete_account_code_failed_attempt = update_columns(delete_account_code_failed_attempts_count: (delete_account_code_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this new email code, was recently sent
    def delete_account_code_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id:,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'message_type' = ?", HawthorneCore::Services::MailerSendSvc::DELETE_ACCOUNT_CODE).
        where("note->'personalization'->'data'->>'code' = ?", delete_account_code).
        where('created_at >= ?', HawthorneCore::User::CODE_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end