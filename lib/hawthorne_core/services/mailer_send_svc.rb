# v3.0

# Mailer Send email service ... ex: send transactions emails (code / back in stock / order confirmation)
# https://developers.mailersend.com/#mailersend-api
class HawthorneCore::Services::MailerSendSvc

  # ----------------------------------------------------------------

  DELETE_ACCOUNT_CODE = 'DELETE ACCOUNT CODE'.freeze
  DELETE_ACCOUNT_CODE_SUBJECT = 'Delete your account'.freeze
  DELETE_ACCOUNT_CODE_TEMPLATE = 'jy7zpl971w3g5vx6'.freeze

  EMAIL_UPDATE_CODE = 'EMAIL UPDATE CODE'.freeze
  EMAIL_UPDATE_CODE_SUBJECT = 'Verify your new email'.freeze
  EMAIL_UPDATE_CODE_TEMPLATE = '3z0vklooo7xl7qrx'.freeze

  SIGN_IN_CODE = 'SIGN-IN CODE'.freeze
  SIGN_IN_CODE_SUBJECT = 'Your sign-in link and code'.freeze
  SIGN_IN_CODE_TEMPLATE = '0r83ql3vnkmgzw1j'.freeze

  WELCOME_EMAIL = 'WELCOME EMAIL'.freeze

  # ----------------------------------------------------------------

  # send delete account code
  def self.send_delete_account_code(user_id:, email:, first_name:, code:, code_formatted:)
    send_email(
      email_type: DELETE_ACCOUNT_CODE,
      user_id:,
      email:,
      subject: DELETE_ACCOUNT_CODE_SUBJECT,
      template_id: DELETE_ACCOUNT_CODE_TEMPLATE,
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
      subject: EMAIL_UPDATE_CODE_SUBJECT,
      template_id: EMAIL_UPDATE_CODE_TEMPLATE,
      personalization: email_update_code_personalization(email:, first_name:, code:, code_formatted:)
    )
  end

  # ----------------------------------------------------------------

  # send sign-in code
  def self.send_sign_in_code(user_id:, user_token:, email:, first_name:, code:, code_formatted:, keep_signed_in:)
    magic_link_url = HawthorneCore::AppConfig.site_base_url + '/verify-sign-in-code-via-magic-link?token=' + user_token + '&code=' + code.to_s + '&keep_signed_in=' + keep_signed_in.to_s
    send_email(
      email_type: SIGN_IN_CODE,
      user_id:,
      email:,
      subject: SIGN_IN_CODE_SUBJECT,
      template_id: SIGN_IN_CODE_TEMPLATE,
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
      subject: "Welcome to #{HawthorneCore::Site.this_site_name}",
      template_id: HawthorneCore::Site.this_site_mailer_send_welcome_email_template_id,
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

  # get the from email for the site, ex: hello@hawthorneprintco.com
  def self.from_email = HawthorneCore::Site.this_site_contact_email

  # get the from name for the site, ex: Hawthorne Print Co
  def self.from_email_name = HawthorneCore::Site.this_site_name

  # get the from tagline for the site, ex: Lindsay, Charlie, and your friends at Hawthorne Print Co
  def self.from_tagline = HawthorneCore::Site.this_site_email_from_tagline

  # ----------------------------------------------------------------

  # define the personalization data element for first name ... if not present, return 'there'
  def self.first_name_personalization(first_name:) = first_name.presence || 'there'

  # define the personalization data for sending a code email
  def self.code_personalization(email:, first_name:, magic_link_url: nil, code:, code_formatted:)
    {
      email:,
      data: {
        first_name: first_name_personalization(first_name:),
        magic_link_url:,
        code:,
        code_formatted:,
        from_tagline:
      }
    }
  end

  # ----------------------

  # define the personalization data for sending the delete account code email
  def self.delete_account_code_personalization(email:, first_name:, code:, code_formatted:) = code_personalization(email:, first_name:, code:, code_formatted:)

  # define the personalization data for sending the email update code email
  def self.email_update_code_personalization(email:, first_name:, code:, code_formatted:) = code_personalization(email:, first_name:, code:, code_formatted:)

  # define the personalization data for sending the sign-in code email
  def self.sign_in_code_personalization(email:, first_name:, magic_link_url:, code:, code_formatted:) = code_personalization(email:, first_name:, magic_link_url:, code:, code_formatted:)

  # ----------------------

  # define the personalization data for sending the welcome email
  def self.welcome_personalization(email:, first_name:)
    {
      email:,
      data: {
        first_name: first_name_personalization(first_name:),
        from_tagline:
      }
    }
  end

  # ----------------------------------------------------------------

  # send an email
  def self.send_email(email_type:, user_id:, email:, subject:, template_id:, personalization:)

    # send the email, via mailer send
    result = mailer_send_email(email:, subject:, template_id:, personalization:)

    # log the email
    HawthorneCore::SentEmail.create!(
      user_id:,
      email_service: 'MAILER_SEND',
      email_type:,
      service_template_id: template_id,
      from_email:,
      to_email: email,
      subject:,
      service_personalization: personalization,
      service_id: result[:message_id],
      exception_caught: !result[:success],
      exception_type: result[:exception_type],
      exception_message: result[:exception_message]
    )

    # log the user action / exception (if caught)
    if result[:success]
      HawthorneCore::UserAction::Log.email_sent(user_id:, note: { email_type:, email:, personalization:, mailer_send_message_id: result[:message_id] })
    else
      HawthorneCore::UserAction::Log.email_sent_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.exception_caught, note: { email_type:, email:, personalization:, exception_message: result[:exception_message] })
      HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::MailerSendSvc.send_email', note: { email_type:, user_id:, email: }, e: result[:exception])
    end

  end

  # ----------------------------------------------------------------

  # send the mailer send email
  def self.mailer_send_email(email:, subject:, template_id:, personalization:)

    # this sends the email
    ms_email = Mailersend::Email.new(client)
    ms_email.add_from(email: from_email, name: from_email_name)
    ms_email.add_recipients(email:)
    ms_email.add_subject(subject)
    ms_email.add_template_id(template_id)
    ms_email.add_personalization(personalization) if personalization.present?
    response = ms_email.send

    # return that the email was successfully sent (specifically 'queued') ... this does not mean delivered
    {
      success: true,
      message_id: response.headers['x-message-id']
    }

    # if an HTTP exception caught
  rescue HTTP::Error => e
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