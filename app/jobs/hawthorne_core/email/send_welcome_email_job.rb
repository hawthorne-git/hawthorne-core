# v3.0

# sends a user a welcome email
class HawthorneCore::Email::SendWelcomeEmailJob < HawthorneCore::ApplicationJob

  queue_as :low

  # ----------------------------------------------------------------

  def perform(user_id, email_address)
    HawthorneCore::Services::MailerSendSvc.send_create_account_email(user_id, email_address)
  end

  # ----------------------------------------------------------------

end