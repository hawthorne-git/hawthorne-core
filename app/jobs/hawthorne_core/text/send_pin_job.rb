# v3.0

# sends a user a text with their pin
class HawthorneCore::Text::SendPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(site_user_id)

    # find the user by id
    site_user = HawthorneCore::SiteUser.
      select(:site_user_id, :phone_number, :pin, :pin_created_at, :nbr_failed_pin_attempts).
      find_by(site_user_id: site_user_id)

    # exit unless the user is found
    unless site_user
      HawthorneCore::SiteUserAction::Log.text_message_sent_failure(nil, HawthorneCore::SiteUserAction::FailureReason.unexpected_state, { type: HawthorneCore::Services::TwilioTextSvc.verification_pin, message: 'Site User not found', site_user_id: site_user_id })
      return
    end

    # exit unless the pin is active
    unless site_user.pin_active?
      HawthorneCore::SiteUserAction::Log.text_message_sent_failure(site_user.id, HawthorneCore::SiteUserAction::FailureReason.pin_expired, { type: HawthorneCore::Services::TwilioTextSvc.verification_pin, pin: site_user.pin, pin_created_at: site_user.pin_created_at })
      return
    end

    # send the text message
    HawthorneCore::Services::TwilioTextSvc.send_verification_pin(site_user.id, site_user.phone_number, site_user.pin)

  end

  # ----------------------------------------------------------------

end