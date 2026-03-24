# v3.0XXX

# sends a user a welcome email
class HawthorneCore::Email::SendWelcomeEmailJob < HawthorneCore::ApplicationJob

  queue_as :low

  # ----------------------------------------------------------------

  def perform(site_user_id, email_address)
    HawthorneCore::Services::MailerSendSvc.send_create_account_email(site_user_id, email_address)
  end

  # ----------------------------------------------------------------

end