# v3.0

# sends a user an email with their pin
class HawthorneCore::Email::SendPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id, keep_signed_in)

    # find the user by id
    user = HawthorneCore::User.
      select(:user_id, :token, :email_address, :pin, :pin_created_at, :pin_failed_attempts_count).
      find_by(user_id: user_id)

    # exit unless the user is found
    unless user
      HawthorneCore::UserAction::Log.email_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, message: 'User not found', user_id: user_id })
      return
    end

    # exit unless the pin is set
    unless user.pin_set?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_set, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, pin: user.pin, pin_created_at: user.pin_created_at })
      return
    end

    # exit if the pin has expired
    if user.pin_expired?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, pin: user.pin, pin_created_at: user.pin_created_at })
      return
    end

    # exit if the max number of failed attempts reached
    if user.pin_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, pin: user.pin, pin_created_at: user.pin_created_at, pin_failed_attempts_count: user.pin_failed_attempts_count })
      return
    end

    # the pin is active, send the email
    HawthorneCore::Services::MailerSendSvc.send_verification_pin(user.id, user.token, user.email_address, user.pin, keep_signed_in)

  end

  # ----------------------------------------------------------------

end