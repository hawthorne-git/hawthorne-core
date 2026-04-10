# v3.0

# sends a user an email with their sign-in pin
class HawthorneCore::Email::SendSignInPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id, keep_signed_in)

    # for user action logs, set the email type
    type = HawthorneCore::Services::MailerSendSvc::SIGN_IN_PIN

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :token, :email_address, :full_name).
      find_by(user_id: user_id)

    # find the users site record ... the pin is specific to the site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :site_id, :user_id, :sign_in_pin, :sign_in_pin_created_at, :sign_in_pin_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # if the pin is inactive, refresh
    user_site.refresh_sign_in_pin unless user_site.sign_in_pin_active?

    # exit if an email with this pin was recently sent to the user
    if user_site.sign_in_pin_recently_sent_via_email?
      HawthorneCore::UserAction::Log.email_sent_failure(user.id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { email_type: type, sign_in_pin: user_site.sign_in_pin })
      return
    end

    # the pin was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_sign_in_pin(user.id, user.token, user.email_address, user.first_name, user_site.sign_in_pin, user_site.sign_in_pin_formatted, keep_signed_in)

  end

  # ----------------------------------------------------------------

end