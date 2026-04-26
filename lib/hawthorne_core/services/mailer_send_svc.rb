# v3.0

# Mailer Send email service ... ex: send transactions emails (code / back in stock / order confirmation)
# https://developers.mailersend.com/#mailersend-api
class HawthorneCore::Services::MailerSendSvc

  # ----------------------------------------------------------------

  DELETE_ACCOUNT_CODE = 'DELETE ACCOUNT CODE'.freeze

  EMAIL_UPDATE_CODE = 'EMAIL UPDATE CODE'.freeze

  SIGN_IN_CODE = 'SIGN-IN CODE'.freeze

  WELCOME_EMAIL = 'WELCOME EMAIL'.freeze

  # ----------------------------------------------------------------

  # send delete account code
  def self.send_delete_account_code(user_id:, email:, first_name:, code:, code_formatted:)
    send_email(
      email_type: DELETE_ACCOUNT_CODE,
      user_id:,
      email:,
      subject: delete_account_code_subject,
      template_id: delete_account_code_template,
      personalization: delete_account_code_personalization(email:, first_name:, code:, code_formatted:)
    )

  end

  # ----------------------------------------------------------------

  # send update email code
  def self.send_email_update_code(user_id:, email:, first_name:, code:, code_formatted:)
    send_email(
      email_type: EMAIL_UPDATE_CODE,
      user_id:,
      email:,
      subject: email_update_code_subject,
      template_id: email_update_code_template,
      personalization: email_update_code_personalization(email:, first_name:, code:, code_formatted:)
    )
  end

  # ----------------------------------------------------------------

  # send sign-in code
  def self.send_sign_in_code(user_id:, user_token:, email:, first_name:, code:, code_formatted:, keep_signed_in:)
    magic_link_url = HawthorneCore::AppConfig.site_base_url + '/verify-sign-in-code-via-magic-link?token=' + user_token + '&code=' + sign_in_code.to_s + '&keep_signed_in=' + keep_signed_in.to_s
    send_email(
      email_type: SIGN_IN_CODE,
      user_id:,
      email:,
      subject: sign_in_code_subject,
      template_id: sign_in_code_template,
      personalization: sign_in_code_personalization(email:, first_name:, magic_link_url:, code:, code_formatted:)
    )
  end

  # ----------------------------------------------------------------

  # send welcome email
  def self.send_welcome_email(user_id:, email:, first_name:)
    send_email(
      email_type: WELCOME_EMAIL,
      user_id:,
      email:,
      subject: welcome_email_subject,
      template_id: welcome_email_template,
      personalization: welcome_personalization(email:, first_name:)
    )
  end

  # ----------------------------------------------------------------

  private

  # ----------------------------------------------------------------

  # create the mailer send client (once)
  def self.client
    @client ||= Mailersend::Client.new(HawthorneCore::AppConfig.mailer_send_api_token)
  end

  # ----------------------------------------------------------------

  def self.from_email = HawthorneCore::Site.this_site_contact_email

  def self.from_email_name = HawthorneCore::Site.this_site_name

  # ----------------------------------------------------------------

  def self.mailer_send_personalization(email:, data:)
    {
      email: email,
      data: data.merge(from_tagline: HawthorneCore::Site.this_site_email_from_tagline)
    }
  end

  def self.first_name_personalization(first_name:) = first_name.presence || 'there'

  # ----------------------

  def self.delete_account_code_subject = 'Delete your account'.freeze

  def self.delete_account_code_template = 'jy7zpl971w3g5vx6'.freeze

  def self.delete_account_code_personalization(email:, first_name:, code:, code_formatted:)
    mailer_send_personalization(
      email:,
      data: {
        first_name: first_name_personalization(first_name:),
        code:,
        code_formatted:
      }
    )
  end

  # ----------------------

  def self.email_update_code_subject = 'Verify your new email'.freeze

  def self.email_update_code_template = '3z0vklooo7xl7qrx'.freeze

  def self.email_update_code_personalization(email:, first_name:, code:, code_formatted:)
    mailer_send_personalization(
      email:,
      data: {
        first_name: first_name_personalization(first_name:),
        code:,
        code_formatted:
      }
    )
  end

  # ----------------------

  def self.sign_in_code_subject = 'Your sign-in link and code'.freeze

  def self.sign_in_code_template = '0r83ql3vnkmgzw1j'.freeze

  def self.sign_in_code_personalization(email:, first_name:, magic_link_url:, code:, code_formatted:)
    mailer_send_personalization(
      email:,
      data: {
        first_name: first_name_personalization(first_name:),
        magic_link_url:,
        code:,
        code_formatted:
      }
    )
  end

  # ----------------------

  def self.welcome_email_subject = 'Welcome to ' + HawthorneCore::Site.this_site_name

  def self.welcome_email_template = HawthorneCore::Site.this_site_mailer_send_welcome_email_template_id

  def self.welcome_personalization(email:, first_name:)
    mailer_send_personalization(
      email:,
      data: {
        first_name: first_name_personalization(first_name:)
      }
    )
  end

  # ----------------------------------------------------------------

  # send an email
  def self.send_email(email_type:, user_id:, email:, subject:, template_id:, personalization:)

    # send the email, via mailer send
    result = mailer_send_email(email:, subject:, template_id:, personalization:)

    # log the email
    HawthorneCore::SentEmail.create!(
      user_id: user_id,
      email_service: 'MAILER_SEND',
      email_type: email_type,
      service_template_id: template_id,
      from_email: from_email,
      to_email: email,
      subject: subject,
      service_personalization: personalization,
      service_id: result[:message_id],
      exception_caught: !result[:success],
      exception_type: result[:exception_type],
      exception_message: result[:exception_message]
    )

    # log the user action / exception (if caught)
    if result[:success]
      HawthorneCore::UserAction::Log.email_sent(user_id:, note: { email_type: email_type, email: email, personalization: personalization, mailer_send_message_id: result[:message_id] })
    else
      HawthorneCore::UserAction::Log.email_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.exception_caught, note: { type: email_type, email: email, personalization: personalization, exception_message: result[:exception_message] })
      HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::MailerSendSvc.send_email', note: { email_type: email_type, user_id: user_id, email: email }, e: result[:exception])
    end

  end

  # ----------------------------------------------------------------

  # send the mailer send email
  def self.mailer_send_email(email:, subject:, template_id:, personalization:)

    # this sends the email
    email = Mailersend::Email.new(client)
    email.add_from(email: from_email, name: from_email_name)
    email.add_recipients(email: email)
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