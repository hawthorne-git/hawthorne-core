# v3.0

module HawthorneCore::UserAction::Log

  # ----------------------------------------------------------------------------- Account

  def self.account_created(user_id, note, ip_address, user_session_token)
    success(user_id, action(:account_created), note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Email

  def self.email_sent(user_id, note)
    success_admin(user_id, action(:email_sent), note)
  end

  def self.email_sent_failure(user_id, failure_reason, note)
    failure_admin(user_id, action(:email_sent), failure_reason, note)
  end

  # ----------------------------------------------------------------------------- Email Address - Verified

  def self.email_address_verified(user_id, note)
    success_admin(user_id, action(:email_address_verified), note)
  end

  # ----------------------------------------------------------------------------- Pin

  def self.pin_cleared(user_id)
    success_admin(user_id, action(:pin_cleared), nil)
  end

  # ------------------------

  def self.pin_created(user_id, note)
    success_admin(user_id, action(:pin_created), note)
  end

  # ------------------------

  def self.pin_verified(user_id, ip_address, user_session_token)
    success(user_id, action(:pin_verified), nil, ip_address, user_session_token)
  end

  def self.pin_verified_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:pin_verified), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Sign-In

  def self.sign_in(user_id)
    success_admin(user_id, action(:sign_in), nil)
  end

  def self.sign_in_failure(failure_reason, note, ip_address, user_session_token)
    failure(nil, action(:sign_in), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Text Message

  def self.text_message_sent(user_id, note)
    success_admin(user_id, action(:text_message_sent), note)
  end

  def self.text_message_sent_failure(user_id, failure_reason, note)
    failure_admin(user_id, action(:text_message_sent), failure_reason, note)
  end

  # -----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------- Core Logger
  # -----------------------------------------------------------------------------

  def self.log(user_id, action, success, failure_reason, note, ip_address, user_session_token)
    HawthorneCore::User::LogActionJob.perform_later(user_id, action, success, failure_reason, note, ip_address, user_session_token)
  end

  # ------------------------

  def self.success(user_id, action, note, ip_address, user_session_token)
    log(user_id, action, true, nil, note, ip_address, user_session_token)
  end

  def self.failure(user_id, action, failure_reason, note, ip_address, user_session_token)
    log(user_id, action, false, failure_reason, note, ip_address, user_session_token)
  end

  # ------------------------

  def self.success_admin(user_id, action, note)
    log(user_id, action, true, nil, note, 'ADMIN', 'ADMIN')
  end

  def self.failure_admin(user_id, action, failure_reason, note)
    log(user_id, action, false, failure_reason, note, 'ADMIN', 'ADMIN')
  end

  # ----------------------------------------------------------------------------- Action Lookup

  # fetch action string from actions module
  def self.action(key) = HawthorneCore::UserAction::Action::ACTIONS.fetch(key)

  # -----------------------------------------------------------------------------

end