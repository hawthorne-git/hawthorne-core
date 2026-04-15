# v3.0

module HawthorneCore::UserSite::DeleteAccountPinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def delete_account_pin_formatted = "#{delete_account_pin[0,3]}-#{delete_account_pin[3,3]}"

    def delete_account_pin_active? = delete_account_pin_set? && !delete_account_pin_expired? && !delete_account_pin_max_failed_attempts_reached?

    def delete_account_pin_set? = delete_account_pin.present? && delete_account_pin_created_at.present?

    def delete_account_pin_expired? = delete_account_pin_created_at.nil? || (delete_account_pin_created_at < HawthorneCore::User::PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def delete_account_pin_max_failed_attempts_reached? = (delete_account_pin_failed_attempts_count >= HawthorneCore::User::PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def delete_account_pin_match?(pin_to_match) = (delete_account_pin == pin_to_match.gsub(/\D/, ''))

    # ------------------------

    # clear the delete account attributes - log it
    def clear_delete_account_attrs
      update_columns(delete_account_pin: nil, delete_account_pin_created_at: nil, delete_account_pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.delete_account_attrs_cleared(user_id)
    end

    # ------------------------

    # set the delete account attributes - log it
    def set_delete_account_attr
      attrs = { delete_account_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), delete_account_pin_created_at: Time.current, delete_account_pin_failed_attempts_count: 0 }
      update_columns(attrs)
      HawthorneCore::UserAction::Log.delete_account_attrs_set(user_id, attrs)
    end

    # ------------------------

    # refresh the users delete account pin / pin created at / failed attempts
    def refresh_delete_account_pin_attrs
      unless delete_account_pin_active?
        attrs = { delete_account_pin: SecureRandom.random_number(HawthorneCore::User::PIN_RANGE), delete_account_pin_created_at: Time.current, delete_account_pin_failed_attempts_count: 0 }
        update_columns(attrs)
        HawthorneCore::UserAction::Log.delete_account_attrs_refreshed(user_id, attrs)
      end
    end

    # refresh the users delete account pin attributes, then send it via email
    def refresh_delete_account_pin_attrs_then_send_it
      refresh_delete_account_pin_attrs
      HawthorneCore::Email::SendDeleteAccountPinJob.perform_later(user_id)
    end

    # ------------------------

    # increment the number of failed attempts with pin
    def add_delete_account_pin_failed_attempt = update_columns(delete_account_pin_failed_attempts_count: (delete_account_pin_failed_attempts_count.to_i + 1))

    # ------------------------

    # determine if an email, with this new email address pin, was recently sent
    def delete_account_pin_recently_sent?
      HawthorneCore::UserAction.
        where(
          site_id: HawthorneCore::Site.this_site_id,
          user_id: user_id,
          action: HawthorneCore::UserAction::Action::ACTIONS.fetch(:email_sent),
          success: true
        ).
        where("note->>'email_type' = ?", HawthorneCore::Services::MailerSendSvc::DELETE_ACCOUNT_PIN).
        where("note->'personalization'->'data'->>'pin' = ?", delete_account_pin).
        where('created_at >= ?', HawthorneCore::User::PIN_RECENTLY_SENT_IN_SECONDS.seconds.ago).
        exists?
    end

    # -----------------------------------------------------------------------------

  end

end