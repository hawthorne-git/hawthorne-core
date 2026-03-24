# v3.0

# Twilio service
class HawthorneCore::Services::TwilioTextSvc

  # ----------------------------------------------------------------

  VERIFICATION_PIN = 'VERIFICATION PIN'.freeze

  def self.verification_pin = VERIFICATION_PIN

  # ----------------------------------------------------------------

  # send a verification pin via text message
  def self.send_verification_pin(site_user_id, phone_number, pin) = send_text_message(VERIFICATION_PIN, site_user_id, phone_number, verification_pin_message(pin))

  # ----------------------------------------------------------------

  private

  # ----------------------------------------------------------------

  # create the twilio client (once)
  def self.client
    @client ||= Twilio::REST::Client.new(
      HawthorneCore::AppConfig.twilio_username,
      HawthorneCore::AppConfig.twilio_password
    )
  end

  # define the phone number to use when sending the text message
  def self.twilio_phone_number = HawthorneCore::AppConfig.twilio_us_phone_number

  # ----------------------------------------------------------------

  # define the verification pin text message - given a pin
  def self.verification_pin_message(pin) = HawthorneCore::Site.this_site_name + ': Your verification pin is ' + pin.to_s + '. It expires in 10 minutes.'

  # ----------------------------------------------------------------

  # send a text message
  def self.send_text_message(text_message_type, site_user_id, phone_number, message)

    # send the text message, via twilio
    result = send_twilio_text_message(twilio_phone_number, phone_number, message)

    # log the text message
    HawthorneCore::SiteTextMessage.create_record(
      text_message_service: 'TWILIO',
      site_user_id: site_user_id,
      text_message_type: text_message_type,
      from_phone_number: twilio_phone_number,
      to_phone_number: phone_number,
      message: message,
      service_id: result[:sid],
      status: result[:status],
      exception_caught: !result[:success],
      exception_type: result[:exception_type],
      exception_code: result[:exception_code],
      exception_message: result[:exception_message]
    )

    # log the user action / exception (if caught)
    if result[:success]
      HawthorneCore::UserAction::Log.text_message_sent(site_user_id, { type: text_message_type, phone_number: phone_number, twilio_message_id: result[:sid] })
    else
      HawthorneCore::UserAction::Log.text_message_sent_failure(site_user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { type: text_message_type, phone_number: phone_number, exception_message: result[:exception_message] })
      HawthorneCore::SiteException.log('HawthorneCore::Services::TwilioTextSvc.send_text_message', { type: text_message_type, site_user_id: site_user_id, phone_number: phone_number }, result[:exception])
    end

  end

  # ----------------------------------------------------------------

  # send the twilio text message
  def self.send_twilio_text_message(from_phone_number, to_phone_number, body)

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