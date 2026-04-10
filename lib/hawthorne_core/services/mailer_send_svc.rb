# v3.0

# Mailer Send email service ... ex: send transactions emails (pin / back in stock / order confirmation)
# https://developers.mailersend.com/#mailersend-api
class HawthorneCore::Services::MailerSendSvc

  # ----------------------------------------------------------------

  EMAIL_ADDRESS_UPDATE_VERIFICATION_PIN = 'EMAIL ADDRESS UPDATE VERIFICATION PIN'.freeze

  SIGN_IN_PIN = 'SIGN-IN VERIFICATION PIN'.freeze

  WELCOME_EMAIL = 'WELCOME EMAIL'.freeze

  # ----------------------------------------------------------------

  # send update email address verification pin
  def self.send_email_address_update_verification_pin(user_id, new_email_address, new_email_address_pin_formatted)
    personalization = email_address_update_verification_pin_personalization(new_email_address, new_email_address_pin_formatted)
    send_email(EMAIL_ADDRESS_UPDATE_VERIFICATION_PIN, user_id, new_email_address, email_address_update_verification_pin_subject, email_address_update_verification_pin_template, personalization)
  end

  # ----------------------------------------------------------------

  # send sign-in verification pin
  def self.send_sign_in_pin(user_id, user_token, email_address, first_name, sign_in_pin, sign_in_pin_formatted, keep_signed_in)
    first_name = first_name || 'there'
    magic_link_url = HawthorneCore::AppConfig.site_base_url + '/verify-sign-in-pin-via-magic-link?token=' + user_token + '&pin=' + sign_in_pin.to_s + '&keep_signed_in=' + keep_signed_in.to_s
    personalization = sign_in_pin_personalization(email_address, first_name, magic_link_url, sign_in_pin_formatted)
    send_email(SIGN_IN_PIN, user_id, email_address, sign_in_pin_subject, sign_in_pin_template, personalization)
  end

  # ----------------------------------------------------------------

  # send welcome email
  def self.send_welcome_email(user_id, email_address)
    send_email(WELCOME_EMAIL, user_id, email_address, welcome_email_subject, welcome_email_template, nil)
  end

  # ----------------------------------------------------------------

  private

  # ----------------------------------------------------------------

  # create the mailer send client (once)
  def self.client
    @client ||= Mailersend::Client.new(HawthorneCore::AppConfig.mailer_send_api_token)
  end

  # ----------------------------------------------------------------

  def self.from_email_address = HawthorneCore::Site.this_site_contact_email

  def self.from_email_address_name = HawthorneCore::Site.this_site_name

  # ----------------------------------------------------------------

  def self.mailer_send_personalization(email_address, data) = { email: email_address, data: data.merge(from_tagline: HawthorneCore::Site.this_site_email_from_tagline) }

  # ----------------------

  def self.email_address_update_verification_pin_subject = 'Verify your new email address'.freeze

  def self.email_address_update_verification_pin_template = '3z0vklooo7xl7qrx'.freeze

  def self.email_address_update_verification_pin_personalization(new_email_address, new_email_address_pin_formatted) = mailer_send_personalization(new_email_address, { pin: new_email_address_pin_formatted })

  # ----------------------

  def self.sign_in_pin_subject = 'Your sign-in link and PIN'.freeze

  def self.sign_in_pin_template = '0r83ql3vnkmgzw1j'.freeze

  def self.sign_in_pin_personalization(email_address, first_name, magic_link_url, sign_in_pin_formatted) = mailer_send_personalization(email_address, { first_name: first_name, magic_link_url: magic_link_url, pin: sign_in_pin_formatted })

  # ----------------------

  def self.welcome_email_subject = 'Welcome to ' + HawthorneCore::Site.this_site_name

  def self.welcome_email_template = HawthorneCore::Site.this_site_mailer_send_welcome_email_template_id

  # ----------------------------------------------------------------

  # send an email
  def self.send_email(email_type, user_id, email_address, subject, template_id, personalization)

    # send the email, via mailer send
    result = mailer_send_email(email_address, subject, template_id, personalization)

    # log the email
    HawthorneCore::SentEmail.create_record(
      user_id: user_id,
      email_service: 'MAILER_SEND',
      email_type: email_type,
      service_template_id: template_id,
      from_email_address: from_email_address,
      to_email_address: email_address,
      subject: subject,
      service_personalization: personalization,
      service_id: result[:message_id],
      exception_caught: !result[:success],
      exception_type: result[:exception_type],
      exception_message: result[:exception_message]
    )

    # log the user action / exception (if caught)
    if result[:success]
      HawthorneCore::UserAction::Log.email_sent(user_id, { email_type: email_type, email_address: email_address, personalization: personalization, mailer_send_message_id: result[:message_id] })
    else
      HawthorneCore::UserAction::Log.email_sent_failure(user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { email_type: email_type, email_address: email_address, personalization: personalization, exception_message: result[:exception_message] })
      HawthorneCore::CapturedException.log('HawthorneCore::Services::MailerSendSvc.send_email', { email_type: email_type, user_id: user_id, email_address: email_address }, result[:exception])
    end

  end

  # ----------------------------------------------------------------

  # send the mailer send email
  def self.mailer_send_email(email_address, subject, template_id, personalization)

    # this sends the email
    email = Mailersend::Email.new(client)
    email.add_from(email: from_email_address, name: from_email_address_name)
    email.add_recipients(email: email_address)
    email.add_subject(subject)
    email.add_template_id(template_id)
    email.add_personalization(personalization) if personalization.present?
    response = email.send

    # return that the email was successfully sent (specifically 'queued') ... this does not mean delivered
    {
      success: true,
      message_id: response.headers['x-message-id']
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