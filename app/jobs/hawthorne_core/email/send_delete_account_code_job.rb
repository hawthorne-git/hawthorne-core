# v3.0

# sends a user an email with their code, to verify that they want to delete their account
class HawthorneCore::Email::SendDeleteAccountCodeJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user by their id
    user = HawthorneCore::User.
      select(:email, :name).
      find_by(user_id:)

    # find the users site record ... the delete account code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :delete_account_code, :delete_account_code_created_at, :delete_account_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # if the code is inactive, refresh
    user_site.refresh_delete_account_attrs.reload unless user_site.delete_account_code_active?

    # exit if an email with this code was recently sent to the user
    if user_site.delete_account_code_recently_sent?
      HawthorneCore::UserAction::Log.email_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.email_recently_sent,note: { message_type: HawthorneCore::Services::MailerSendSvc::DELETE_ACCOUNT_CODE, delete_account_code: user_site.delete_account_code })
      return
    end

    # the code was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_delete_account_code(
      user_id:,
      email: user.email,
      first_name: user.first_name,
      code: user_site.delete_account_code,
      code_formatted: user_site.delete_account_code_formatted
    )

    end

  # ----------------------------------------------------------------

end