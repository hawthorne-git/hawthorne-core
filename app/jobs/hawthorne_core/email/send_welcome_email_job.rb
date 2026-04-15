# v3.0

# sends a user a welcome email
class HawthorneCore::Email::SendWelcomeEmailJob < HawthorneCore::ApplicationJob

  queue_as :low

  # ----------------------------------------------------------------

  def perform(user_id, email_address)

    # find the users first name - used in the greeting of the email
    first_name = HawthorneCore::User.select(:full_name).find_by(user_id: user_id).first_name

    # send the email
    HawthorneCore::Services::MailerSendSvc.send_welcome_email(user_id, email_address, first_name)

  end

  # ----------------------------------------------------------------

end