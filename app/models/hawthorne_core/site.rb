# v3.0

class HawthorneCore::Site < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::Site::RileyBlake

  # -----------------------------------------------------------------------------

  self.table_name = 'sites'

  def id = site_id

  # -----------------------------------------------------------------------------

  # define the list of contact emails, by site
  CONTACT_EMAILS =
    {
      riley_blake_env_name => riley_blake_contact_email
    }

  # define the list of email from taglines, by site
  EMAIL_FROM_TAGLINES =
    {
      riley_blake_env_name => riley_blake_email_from_tagline
    }

  # define the list of has checkouts, by site
  # as ex: hawthorne-supply-co has a checkout, while hawthorne-admin does not
  HAS_CHECKOUTS =
    {
      riley_blake_env_name => riley_blake_has_checkout
    }

  # define the list of site ids
  IDS =
    {
      riley_blake_env_name => riley_blake_id
    }

  # define the list of mailer send welcome template ids
  MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS =
    {
      riley_blake_env_name => riley_blake_mailer_send_welcome_template_id
    }

  # define the list of site names
  NAMES =
    {
      riley_blake_env_name => riley_blake_name
    }

  SITE_SHARING_SCOPES =
    {
      riley_blake_env_name => riley_blake_site_sharing_scope
    }

  # -----------------------------------------------------------------------------

  def self.this_site_contact_email = CONTACT_EMAILS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_contact_email') }

  def self.this_site_email_from_tagline = EMAIL_FROM_TAGLINES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_email_from_tagline') }

  def self.this_site_has_checkout? = HAS_CHECKOUTS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_has_checkout?') }

  def self.this_site_id = IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_id') }

  def self.this_site_mailer_send_welcome_email_template_id = MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_mailer_send_welcome_email_template_id') }

  def self.this_site_name = NAMES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_name') }

  def self.this_site_sharing_scope = SITE_SHARING_SCOPES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_sharing_scope') }

  # -----------------------------------------------------------------------------

  def self.header_version = with_reading { where(site_id: this_site_id).pick(:header_version) }

  def self.footer_version = with_reading { where(site_id: this_site_id).pick(:footer_version) }

  # -----------------------------------------------------------------------------

  private

  # in the case where site name is not expected,
  # return the raised exception - which includes the method name and ENV['SITE_NAME']
  def self.env_site_name_exception(method_name)
    %(Exception: Unexpected ENV["SITE_NAME"] in method HawthorneCore::Site.#{method_name}, ENV["SITE_NAME"] = "#{HawthorneCore::AppConfig.site_name}")
  end

  # -----------------------------------------------------------------------------

end