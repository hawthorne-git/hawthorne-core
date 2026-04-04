# v3.0

class HawthorneCore::Site < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::Site::HawthorneAdmin,
          HawthorneCore::Site::HawthorneArtists,
          HawthorneCore::Site::HawthornePrintCo,
          HawthorneCore::Site::HawthorneSupplyCo,
          HawthorneCore::Site::RileyBlake

  # -----------------------------------------------------------------------------

  self.table_name = 'sites'

  def id = site_id

  # -----------------------------------------------------------------------------

  # define the list of contact emails, by site
  # note that not all sites have a contact email; ex hawthorne-admin
  CONTACT_EMAILS =
    {
      hawthorne_artists_env_name => hawthorne_artists_contact_email,
      hawthorne_print_co_env_name => hawthorne_print_co_contact_email,
      hawthorne_supply_co_env_name => hawthorne_supply_co_contact_email,
      riley_blake_env_name => riley_blake_contact_email
    }

  # define the list of email from taglines, by site
  # note that not all sites have an email from tagline; ex hawthorne-admin
  EMAIL_FROM_TAGLINES =
    {
      hawthorne_artists_env_name => hawthorne_artists_email_from_tagline,
      hawthorne_print_co_env_name => hawthorne_print_co_email_from_tagline,
      hawthorne_supply_co_env_name => hawthorne_supply_co_email_from_tagline,
      riley_blake_env_name => riley_blake_email_from_tagline
    }

  # define the list of has checkouts, by site
  # as ex: hawthorne-supply-co has a checkout, while hawthorne-admin does not
  HAS_CHECKOUTS =
    {
      hawthorne_admin_env_name => hawthorne_admin_has_checkout,
      hawthorne_artists_env_name => hawthorne_artists_has_checkout,
      hawthorne_print_co_env_name => hawthorne_print_co_has_checkout,
      hawthorne_supply_co_env_name => hawthorne_supply_co_has_checkout,
      riley_blake_env_name => riley_blake_has_checkout
    }

  # define the list of site ids, by site
  IDS =
    {
      hawthorne_admin_env_name => hawthorne_admin_id,
      hawthorne_artists_env_name => hawthorne_artists_id,
      hawthorne_print_co_env_name => hawthorne_print_co_id,
      hawthorne_supply_co_env_name => hawthorne_supply_co_id,
      riley_blake_env_name => riley_blake_id
    }

  # define the list of mailer send welcome template ids, by site
  # note that not all sites send welcome emails; ex hawthorne-admin
  MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS =
    {
      hawthorne_artists_env_name => hawthorne_artists_mailer_send_welcome_template_id,
      hawthorne_print_co_env_name => hawthorne_print_co_mailer_send_welcome_template_id,
      hawthorne_supply_co_env_name => hawthorne_supply_co_mailer_send_welcome_template_id,
      riley_blake_env_name => riley_blake_mailer_send_welcome_template_id
    }

  # define the list of site names, by site
  NAMES =
    {
      hawthorne_admin_env_name => hawthorne_admin_name,
      hawthorne_artists_env_name => hawthorne_artists_name,
      hawthorne_print_co_env_name => hawthorne_print_co_name,
      hawthorne_supply_co_env_name => hawthorne_supply_co_name,
      riley_blake_env_name => riley_blake_name
    }

  # define the list of site name abbreviations, by site
  NAME_ABBREVIATIONS =
    {
      hawthorne_admin_env_name => hawthorne_admin_name_abbreviation,
      hawthorne_artists_env_name => hawthorne_artists_name_abbreviation,
      hawthorne_print_co_env_name => hawthorne_print_co_name_abbreviation,
      hawthorne_supply_co_env_name => hawthorne_supply_co_name_abbreviation,
      riley_blake_env_name => riley_blake_name_abbreviation
    }

  # define the list of site sharing scopes, by site
  SITE_SHARING_SCOPES =
    {
      hawthorne_admin_env_name => hawthorne_admin_site_sharing_scope,
      hawthorne_artists_env_name => hawthorne_artists_site_sharing_scope,
      hawthorne_print_co_env_name => hawthorne_print_co_site_sharing_scope,
      hawthorne_supply_co_env_name => hawthorne_supply_co_site_sharing_scope,
      riley_blake_env_name => riley_blake_site_sharing_scope
    }

  # -----------------------------------------------------------------------------

  def self.this_site_contact_email = CONTACT_EMAILS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_contact_email') }

  def self.this_site_email_from_tagline = EMAIL_FROM_TAGLINES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_email_from_tagline') }

  def self.this_site_has_checkout? = HAS_CHECKOUTS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_has_checkout?') }

  def self.this_site_id = IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_id') }

  def self.this_site_mailer_send_welcome_email_template_id = MAILER_SEND_WELCOME_EMAIL_TEMPLATE_IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_mailer_send_welcome_email_template_id') }

  def self.this_site_name = NAMES.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_name') }

  def self.this_site_name_abbreviation = NAME_ABBREVIATIONS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_name_abbreviation') }

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