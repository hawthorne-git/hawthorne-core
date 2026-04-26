# v3.0

# sends a user a welcome email
class HawthorneCore::Email::SendWelcomeEmailJob < HawthorneCore::ApplicationJob

  queue_as :low

  # ----------------------------------------------------------------

  def perform(user_id)

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :email, :name).
      active.
      find_by(user_id: user_id)

    # send the email
    HawthorneCore::Services::MailerSendSvc.send_welcome_email(user.id, user.email, user.first_name)

  end

  # ----------------------------------------------------------------

end