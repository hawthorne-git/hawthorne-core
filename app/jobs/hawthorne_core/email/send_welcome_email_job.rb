# v3.0

# sends a user a welcome email
class HawthorneCore::Email::SendWelcomeEmailJob < HawthorneCore::ApplicationJob

  queue_as :low

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user by their id
    user = HawthorneCore::User.find_by(user_id:)

    # send the email
    HawthorneCore::Services::MailerSendSvc.send_welcome_email(
      user_id: user.id,
      email: user.email,
      first_name: user.first_name
    )

  end

  # ----------------------------------------------------------------

end