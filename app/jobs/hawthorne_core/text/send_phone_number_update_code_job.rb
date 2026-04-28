# v3.0

# sends a user a text message with their code, to verify their new phone number
class HawthorneCore::Text::SendPhoneNumberUpdateCodeJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the users site record ... the new phone number code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_phone_number, :new_phone_number_code, :new_phone_number_code_created_at, :new_phone_number_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # if the code is inactive, refresh and reload the model
    user_site.refresh_new_phone_number_code_attrs.reload unless user_site.new_phone_number_code_active?

    # exit if a text message with this code was recently sent to the user
    if user_site.new_phone_number_code_recently_sent?
      HawthorneCore::UserAction::Log.text_message_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.text_message_recently_sent, note: { type: HawthorneCore::Services::TwilioTextSvc::PHONE_NUMBER_UPDATE_CODE, new_phone_number: user_site.new_phone_number, new_phone_number_code: user_site.new_phone_number_code })
      return
    end

    # the code was not recently sent, send the text message
    HawthorneCore::Services::TwilioTextSvc.send_phone_number_update_code(
      user_id:,
      phone_number: user_site.new_phone_number,
      code_formatted: user_site.new_phone_number_code_formatted
    )

  end

  # ----------------------------------------------------------------

end