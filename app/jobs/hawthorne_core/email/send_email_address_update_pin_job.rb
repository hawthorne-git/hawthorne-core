# v3.0

# sends a user an email with their pin, to verify their new email address
class HawthorneCore::Email::SendEmailAddressUpdatePinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # find the user by id
    user = HawthorneCore::User.
      select(:user_id, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: user_id)

    # exit unless the user is found
    unless user
      HawthorneCore::UserAction::Log.email_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { email_type: HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin, message: 'User not found', user_id: user_id })
      return
    end

    # exit unless the pin is set
    unless user.email_address_update_pin_set?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_set, { email_type: HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin, new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at })
      return
    end

    # exit if the pin has expired
    if user.email_address_update_pin_expired?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { email_type: HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin, new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at })
      return
    end

    # exit if the max number of failed attempts reached
    if user.email_address_update_pin_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached, { email_type: HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin, new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at, new_email_address_pin_failed_attempts_count: user.new_email_address_pin_failed_attempts_count })
      return
    end

    # exit if an email with this pin was recently sent
    if user.email_address_update_pin_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { email_type: HawthorneCore::Services::MailerSendSvc.email_address_update_verification_pin, new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at, new_email_address_pin_failed_attempts_count: user.new_email_address_pin_failed_attempts_count })
      return
    end

    # the pin is active, send the email
    HawthorneCore::Services::MailerSendSvc.send_email_address_update_verification_pin(user.id, user.new_email_address, user.new_email_address_pin)

  end

  # ----------------------------------------------------------------

end