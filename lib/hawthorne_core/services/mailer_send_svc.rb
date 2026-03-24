# v3.0XXX

# Mailer Send email service ... ex: send transactions emails (pin / back in stock / order confirmation)
# https://developers.mailersend.com/#mailersend-api
class HawthorneCore::Services::MailerSendSvc

  # ----------------------------------------------------------------

  VERIFICATION_PIN = 'VERIFICATION PIN'.freeze

  def self.verification_pin = VERIFICATION_PIN

  # ----------------------------------------------------------------

  # send a verification pin via email
  def self.send_verification_pin(site_user_id, site_user_token, email_address, pin)
    email_address = 'charlieprezzano@gmail.com'
    magic_link_url = HawthorneCore::AppConfig.site_base_url + '/verify-pin-via-magic-link?token=' + site_user_token + '&pin=' + pin.to_s
    personalization = verification_pin_personalization(email_address, magic_link_url, pin)
    send_email(VERIFICATION_PIN, site_user_id, email_address, verification_pin_subject, verification_pin_template, personalization)
  end

  # ----------------------------------------------------------------

  private

  # ----------------------------------------------------------------

  # create the mailer send client (once)
  def self.client
    @client ||= Mailersend::Client.new(HawthorneCore::AppConfig.mailer_send_api_token)
  end

  # ----------------------------------------------------------------

  # define who the email address is from (ex: contat@hawthornesupplyco.com)
  def self.from_email_address = HawthorneCore::Site.this_site_contact_email

  # define who the name of the email address is from (ex: Hawthorne Supply Co)
  def self.from_email_address_name = HawthorneCore::Site.this_site_name

  # ----------------------------------------------------------------

  # build the personalization attribute, which is email address + data
  def self.personalization_with_email_address(email_address, data) = { email: email_address, data: data }

  # ----------------------

  def self.verification_pin_subject = 'Verify your email address'

  def self.verification_pin_template = '0r83ql3vnkmgzw1j'

  def self.verification_pin_personalization(email_address, magic_link_url, pin) = personalization_with_email_address(email_address, { magic_link_url: magic_link_url, pin: pin })

  # ----------------------------------------------------------------

  # send an email
  def self.send_email(email_type, site_user_id, email_address, subject, template_id, personalization)

    # send the email, via mailer send
    result = mailer_send_email(email_address, subject, template_id, personalization)

    # log the email
    HawthorneCore::SiteEmail.create_record(
      email_service: 'MAILER_SEND',
      site_user_id: site_user_id,
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
      HawthorneCore::UserAction::Log.email_sent(site_user_id, { type: email_type, email_address: email_address, personalization: personalization, mailer_send_message_id: result[:message_id] })
    else
      HawthorneCore::UserAction::Log.email_sent_failure(site_user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { type: email_type, email_address: email_address, personalization: personalization, exception_message: result[:exception_message] })
      HawthorneCore::SiteException.log('HawthorneCore::Services::MailerSendSvc.send_email', { type: email_type, site_user_id: site_user_id, email_address: email_address }, result[:exception])
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