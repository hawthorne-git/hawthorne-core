# v3.0

# sends a user an email with their code, to verify their new email
class HawthorneCore::Email::SendEmailUpdateCodeJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user by their id
    user = HawthorneCore::User.
      select(:name).
      find_by(user_id:)

    # find the users site record ... the new email code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email, :new_email_code, :new_email_code_created_at, :new_email_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # if the code is inactive, refresh and reload the model
    user_site.refresh_new_email_attrs.reload unless user_site.new_email_code_active?

    # exit if an email with this code was recently sent to the user
    if user_site.new_email_code_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.email_recently_sent, note: { type: HawthorneCore::Services::MailerSendSvc::EMAIL_UPDATE_CODE, new_email: user_site.new_email, new_email_code: user_site.new_email_code })
      return
    end

    # the code was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_email_update_code(
      user_id:,
      email: user_site.new_email,
      first_name: user.first_name,
      code: user_site.new_email_code,
      code_formatted: user_site.new_email_code_formatted
    )

  end

  # ----------------------------------------------------------------

end