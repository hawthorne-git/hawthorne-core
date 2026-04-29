# v3.0

# sends a user an email with their sign-in code
class HawthorneCore::Email::SendSignInCodeJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:, keep_signed_in: false)

    # find the user by their id
    user = HawthorneCore::User.
      select(:token, :email, :name).
      active.
      find_by(user_id:)

    # find the users site record ... the code is specific to the site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :sign_in_code, :sign_in_code_created_at, :sign_in_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # if the code is inactive, refresh and reload the model
    user_site.refresh_sign_in_attrs.reload unless user_site.sign_in_code_active?

    # exit if an email with this code was recently sent to the user
    if user_site.sign_in_code_recently_sent_via_email?
      HawthorneCore::UserAction::Log.email_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.email_recently_sent, note: { type: HawthorneCore::Services::MailerSendSvc::SIGN_IN_CODE, sign_in_code: user_site.sign_in_code })
      return
    end

    # the code was not recently sent, send the email
    HawthorneCore::Services::MailerSendSvc.send_sign_in_code(
      user_id:,
      user_token: user.token,
      email: user.email,
      first_name: user.first_name,
      code: user_site.sign_in_code,
      code_formatted: user_site.sign_in_code_formatted,
      keep_signed_in:
    )

  end

  # ----------------------------------------------------------------

end