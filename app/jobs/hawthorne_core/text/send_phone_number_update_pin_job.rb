# v3.0

# sends a user a text message with their pin, to verify their new phone number
class HawthorneCore::Text::SendPhoneNumberUpdatePinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the text message type
    type = HawthorneCore::Services::TwilioTextSvc::PHONE_NUMBER_UPDATE_VERIFICATION_PIN

    # find the users site record ... the new phone number pin is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_phone_number, :new_phone_number_pin, :new_phone_number_pin_created_at, :new_phone_number_pin_failed_attempts_count).
      find_by(user_id: user_id, site_id: HawthorneCore::Site.this_site_id)

    # if the pin is inactive, refresh
    user_site.refresh_new_phone_number_pin_attrs unless user_site.new_phone_number_pin_active?

    # exit if a text message with this pin was recently sent to the user
    if user_site.new_phone_number_pin_recently_sent?
      HawthorneCore::UserAction::Log.text_message_sent_failure(user_site.user_id, HawthorneCore::UserAction::FailureReason.text_message_recently_sent, { text_message_type: type, new_phone_number: user_site.new_phone_number, new_phone_number_pin: user_site.new_phone_number_pin })
      return
    end

    # the pin was not recently sent, send the text message
    HawthorneCore::Services::TwilioTextSvc.send_phone_number_update_verification_pin(user_site.user_id, user_site.new_phone_number, user_site.new_phone_number_pin_formatted)

  end

  # ----------------------------------------------------------------

end