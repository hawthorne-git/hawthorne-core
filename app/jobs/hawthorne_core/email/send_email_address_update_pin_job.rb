# v3.0

# sends a user an email with their pin, to verify their new email address
class HawthorneCore::Email::SendEmailAddressUpdatePinJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # for user action logs, set the email type
    type = HawthorneCore::Services::MailerSendSvc::EMAIL_ADDRESS_UPDATE_PIN

    # find the users site record ... the new email address pin is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: user_id, site_id: HawthorneCore::Site.this_site_id)

    # if the pin is inactive, refresh
    user_site.refresh_new_email_address_pin_attrs unless user_site.new_email_address_pin_active?

    # exit if an email with this pin was recently sent to the user
    if user_site.new_email_address_pin_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user_site.user_id, HawthorneCore::UserAction::FailureReason.email_recently_sent, { type: type, new_email_address: user_site.new_email_address, new_email_address_pin: user_site.new_email_address_pin })
      return
    end

    # find the users first name - used in the greeting of the email
    user_first_name = HawthorneCore::User.select(:full_name).find_by(user_id: user_id).first_name

    # the pin was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_email_address_update_pin(user_site.user_id, user_first_name, user_site.new_email_address, user_site.new_email_address_pin_formatted)

  end

  # ----------------------------------------------------------------

end