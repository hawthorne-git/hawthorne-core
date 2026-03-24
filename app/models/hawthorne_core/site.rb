# v3.0

class HawthorneCore::Site < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::Site::RileyBlake

  # -----------------------------------------------------------------------------

  self.table_name = 'sites'

  def id = site_id

  # -----------------------------------------------------------------------------

  # define the list of site contact emails
  SITE_CONTACT_EMAILS =
    {
      riley_blake_env_name => riley_blake_contact_email
    }

  # define the list of site ids
  SITE_IDS =
    {
      riley_blake_env_name => riley_blake_id
    }

  # define the list of mailer send welcome template ids
  SITE_MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS =
    {
      riley_blake_env_name => riley_blake_mailer_send_welcome_template_id
    }

  # define the list of site names
  SITE_NAMES =
    {
      riley_blake_env_name => riley_blake_name
    }

  # -----------------------------------------------------------------------------

  # get the site id, from the ENV attribute SITE_NAME
  def self.this_site_id
    SITE_IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_id') }
  end

  # get the site name, from the ENV attribute SITE_NAME
  def self.this_site_name
    SITE_NAMES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_name') }
  end

  # get the site contact email, from the ENV attribute SITE_NAME
  def self.this_site_contact_email
    SITE_CONTACT_EMAILS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_contact_email') }
  end

  # get the site mailer send welcome email template id, from the ENV attribute SITE_NAME
  def self.this_site_mailer_send_welcome_email_template_id
    SITE_MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_mailer_send_welcome_email_template_id') }
  end

  # -----------------------------------------------------------------------------

  # get the sites header version
  def self.header_version
    with_reading { where(site_id: this_site_id).pick(:header_version) }
  end

  # -------------------------

  # get the sites footer version
  def self.footer_version
    with_reading { where(site_id: this_site_id).pick(:footer_version) }
  end

  # -----------------------------------------------------------------------------

  private

  # in the case where site name is not expected,
  # return the raised exception - which includes the method name and ENV['SITE_NAME']
  def self.env_site_name_exception(method_name)
    %(Exception: Unexpected ENV["SITE_NAME"] in method HawthorneCore::Site.#{method_name}, ENV["SITE_NAME"] = "#{HawthorneCore::AppConfig.site_name}")
  end

  # -----------------------------------------------------------------------------

end