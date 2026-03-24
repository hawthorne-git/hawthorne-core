# v3.0XXX

# sends a user an email with their pin
class HawthorneCore::Email::SendPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(site_user_id)

    # find the user by id
    site_user = HawthorneCore::User.
      select(:site_user_id, :small_web_id, :email_address, :pin, :pin_created_at, :nbr_failed_pin_attempts).
      find_by(site_user_id: site_user_id)

    # todo: for testing ...
    site_user.refresh_pin

    # exit unless the user is found
    unless site_user
      HawthorneCore::UserAction::Log.email_sent_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, message: 'Site User not found', site_user_id: site_user_id })
      return
    end

    # exit unless the pin is active
    unless site_user.pin_active?
       HawthorneCore::UserAction::Log.email_sent_failure(site_user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { type: HawthorneCore::Services::MailerSendSvc.verification_pin, pin: site_user.pin, pin_created_at: site_user.pin_created_at })
      return
    end

    # send the email
    HawthorneCore::Services::MailerSendSvc.send_verification_pin(site_user.id, site_user.token, site_user.email_address, site_user.pin)

  end

  # ----------------------------------------------------------------

end