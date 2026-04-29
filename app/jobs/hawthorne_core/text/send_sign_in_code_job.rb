# v3.0

# sends a user a text message with their sign-in code
class HawthorneCore::Text::SendSignInCodeJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the users phone number
    phone_number = HawthorneCore::User.where(user_id:).pick(:phone_number)

    # find the users site record ... the sign-in code is specific to the site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :sign_in_code, :sign_in_code_created_at, :sign_in_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # if the code is inactive, refresh and reload the model
    user_site.refresh_sign_in_attrs.reload unless user_site.sign_in_code_active?

    # exit if a text message with this code was recently sent to the user
    if user_site.sign_in_code_recently_sent_via_text_message?
      HawthorneCore::UserAction::Log.text_message_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.text_message_recently_sent, note: { type: HawthorneCore::Services::TwilioTextSvc::SIGN_IN_CODE, sign_in_code: user_site.sign_in_code })
      return
    end

    # the code was not recently sent, send the text message
    HawthorneCore::Services::TwilioTextSvc.send_sign_in_code(
      user_id:,
      phone_number:,
      code_formatted: user_site.sign_in_code_formatted
    )

  end

  # ----------------------------------------------------------------

end