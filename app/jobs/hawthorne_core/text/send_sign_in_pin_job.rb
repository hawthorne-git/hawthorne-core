# v3.0

# sends a user a text message with their pin, to sign-in
class HawthorneCore::Text::SendSignInPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the text message type
    type = HawthorneCore::Services::TwilioTextSvc::SIGN_IN_VERIFICATION_PIN

    # find the user by id
    user = HawthorneCore::User.
      select(:user_id, :phone_number, :pin, :pin_created_at, :pin_failed_attempts_count).
      find_by(user_id: user_id)

    # exit unless the user is found
    unless user
      HawthorneCore::UserAction::Log.text_message_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { text_message_type: type, message: 'User not found', user_id: user_id })
      return
    end

    # if the pin is inactive, refresh
    user.refresh_sign_in_pin unless user.sign_in_pin_active?

    # exit if a text message with this pin was recently sent to the user
    if user.sign_in_pin_recently_sent_via_text_message?
      HawthorneCore::UserAction::Log.text_message_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.text_message_recently_sent, { text_message_type: type, pin: user.pin })
      return
    end

    # the pin was not recently sent, send the text message
    HawthorneCore::Services::TwilioTextSvc.send_sign_in_verification_pin(user.id, user.phone_number, user.sign_in_pin_formatted)

  end

  # ----------------------------------------------------------------

end