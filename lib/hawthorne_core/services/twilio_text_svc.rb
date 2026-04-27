# v3.0

# Twilio service
class HawthorneCore::Services::TwilioTextSvc

  # ----------------------------------------------------------------

  PHONE_NUMBER_UPDATE_CODE = 'PHONE NUMBER UPDATE CODE'.freeze

  SIGN_IN_CODE = 'SIGN-IN CODE'.freeze

  # ----------------------------------------------------------------

  # send update phone number code
  def self.send_phone_number_update_code(user_id:, phone_number:, code_formatted:)
    send_text_message(
      text_message_type: PHONE_NUMBER_UPDATE_CODE,
      user_id:,
      phone_number: phone_number,
      message: code_message(code: code_formatted)
    )
  end

  # send sign-in code
  def self.send_sign_in_code(user_id:, phone_number:, code_formatted:)
    send_text_message(
      text_message_type: SIGN_IN_CODE,
      user_id:,
      phone_number: phone_number,
      message: sign_in_code_message(code: code_formatted)
    )
  end

  # ----------------------------------------------------------------

  private

  # ----------------------------------------------------------------

  # create the twilio client (once)
  def self.client
    @client ||= Twilio::REST::Client.new(HawthorneCore::AppConfig.twilio_username, HawthorneCore::AppConfig.twilio_password)
  end

  # define the phone number to use when sending the text message
  def self.twilio_phone_number = '18452534739'.freeze

  # ----------------------------------------------------------------

  # define the sign-in code text message - given a code
  def self.sign_in_code_message(code:) = "#{HawthorneCore::Site.this_site_name}\n\nYour sign-in code is #{code}"

  # define the code text message - given a code
  def self.code_message(code:) = "#{HawthorneCore::Site.this_site_name}\n\nYour code is #{code}."

  # ----------------------------------------------------------------

  # send a text message
  def self.send_text_message(text_message_type:, user_id:, phone_number:, message:)

    # send the text message, via twilio
    result = send_twilio_text_message(
      from_phone_number: twilio_phone_number,
      to_phone_number: phone_number,
      body: message
    )

    # log the text message
    HawthorneCore::SentTextMessage.create!(
      user_id:,
      text_message_service: 'TWILIO',
      text_message_type: text_message_type,
      from_phone_number: twilio_phone_number,
      to_phone_number: phone_number,
      message: message,
      service_id: result[:sid],
      service_status: result[:status],
      exception_caught: !result[:success],
      exception_type: result[:exception_type],
      exception_code: result[:exception_code],
      exception_message: result[:exception_message]
    )

    # log the user action / exception (if caught)
    if result[:success]
      HawthorneCore::UserAction::Log.text_message_sent(user_id:, note: { text_message_type: text_message_type, phone_number: phone_number, message: message, twilio_message_id: result[:sid] })
    else
      HawthorneCore::UserAction::Log.text_message_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.exception_caught, note: { type: text_message_type, phone_number: phone_number, message: message, exception_message: result[:exception_message] })
      HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::TwilioTextSvc.send_text_message', note: { type: text_message_type, user_id:, phone_number: phone_number, message: message }, e: result[:exception])
    end

  end

  # ----------------------------------------------------------------

  # send the twilio text message
  def self.send_twilio_text_message(from_phone_number:, to_phone_number:, body:)

    # this sends the text message
    message = client.messages.create(
      from: from_phone_number,
      to: to_phone_number,
      body: body,
      status_callback: 'https://www.hawthonreadmin.com/callback_twilio_xklgyhzfnvro'
    )

    # return that the text message was successfully sent (specifically 'queued') ... this does not mean delivered
    {
      success: true,
      sid: message.sid,
      status: message.status
    }

    # if a twilio execution caught ...
  rescue Twilio::REST::RestError => e
    {
      success: false,
      exception_type: :twilio_error,
      exception: e,
      exception_code: e.code,
      exception_message: e.message
    }

    # if an HTTP exception caught
  rescue Faraday::Error => e
    {
      success: false,
      exception_type: :network_error,
      exception: e,
      exception_message: e.message
    }

    # catch all other exceptions
  rescue => e
    {
      success: false,
      exception_type: :unknown_error,
      exception: e,
      exception_message: e.message
    }

  end

  # ----------------------------------------------------------------

end