# v3.0

# sends a user a text message with their sign-in pin
class HawthorneCore::Text::SendSignInPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the text message type
    type = HawthorneCore::Services::TwilioTextSvc::SIGN_IN_PIN

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :phone_number).
      find_by(user_id: user_id)

    # find the users site record ... the pin is specific to the site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :site_id, :user_id, :sign_in_pin, :sign_in_pin_created_at, :sign_in_pin_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # if the pin is inactive, refresh
    user_site.refresh_sign_in_pin unless user_site.sign_in_pin_active?

    # exit if a text message with this pin was recently sent to the user
    if user_site.sign_in_pin_recently_sent_via_text_message?
      HawthorneCore::UserAction::Log.text_message_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.text_message_recently_sent, { text_message_type: type, sign_in_pin: user_site.sign_in_pin })
      return
    end

    # the pin was not recently sent, send the text message
    HawthorneCore::Services::TwilioTextSvc.send_sign_in_pin(user.id, user.phone_number, user_site.sign_in_pin_formatted)

  end

  # ----------------------------------------------------------------

end