# v3.0

# sends a user an email with their pin, to sign-in
class HawthorneCore::Email::SendSignInPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id, keep_signed_in)

    # for user action logs, set the email type
    type = HawthorneCore::Services::MailerSendSvc::SIGN_IN_VERIFICATION_PIN

    # find the user by id
    user = HawthorneCore::User.
      select(:user_id, :token, :email_address, :pin, :pin_created_at, :pin_failed_attempts_count).
      find_by(user_id: user_id)

    # exit unless the user is found
    unless user
      HawthorneCore::UserAction::Log.email_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { email_type: type, message: 'User not found', user_id: user_id })
      return
    end

    # if the pin is inactive, refresh
    user.refresh_sign_in_pin unless user.sign_in_pin_active?

    # exit if an email with this pin was recently sent to the user
    if user.sign_in_pin_recently_sent_via_email?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { email_type: type, pin: user.pin })
      return
    end

    # the pin was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_sign_in_verification_pin(user.id, user.token, user.email_address, user.pin, keep_signed_in)

  end

  # ----------------------------------------------------------------

end