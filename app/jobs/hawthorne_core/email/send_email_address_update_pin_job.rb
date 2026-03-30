# v3.0

# sends a user an email with their pin, to verify their new email address
class HawthorneCore::Email::SendEmailAddressUpdatePinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the email type
    type = HawthorneCore::Services::MailerSendSvc::EMAIL_ADDRESS_UPDATE_VERIFICATION_PIN

    # find the user by id
    user = HawthorneCore::User.
      select(:user_id, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: user_id)

    # exit unless the user is found
    unless user
      HawthorneCore::UserAction::Log.email_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { type: type, message: 'User not found', user_id: user_id })
      return
    end

    # if the pin is inactive, refresh
    user.refresh_email_address_update_pin_attrs unless user.email_address_update_pin_active?

    # exit if an email with this pin was recently sent to the user
    if user.email_address_update_pin_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { type: type, new_email_address_pin: user.new_email_address_pin })
      return
    end

    # the pin was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_email_address_update_verification_pin(user.id, user.new_email_address, user.new_email_address_pin_formatted)

  end

  # ----------------------------------------------------------------

end