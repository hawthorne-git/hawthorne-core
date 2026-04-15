# v3.0

# sends a user an email with their pin, to verify that they want to delete their account
class HawthorneCore::Email::SendDeleteAccountPinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the email type
    type = HawthorneCore::Services::MailerSendSvc::DELETE_ACCOUNT_PIN

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name).
      find_by(user_id: user_id)

    # find the users site record ... the delete account pin is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :delete_account_pin, :delete_account_pin_created_at, :delete_account_pin_failed_attempts_count).
      find_by(user_id: user_id, site_id: HawthorneCore::Site.this_site_id)

    # if the pin is inactive, refresh
    user_site.refresh_delete_account_pin_attrs unless user_site.delete_account_pin_active?

    # exit if an email with this pin was recently sent to the user
    if user_site.delete_account_pin_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user_site.user_id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { type: type, delete_account_pin: user_site.delete_account_pin })
      return
    end

    # the pin was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_delete_account_pin(user_site.user_id, user.email_address, user.first_name, user_site.delete_account_pin,  user_site.delete_account_pin_formatted)

  end

  # ----------------------------------------------------------------

end