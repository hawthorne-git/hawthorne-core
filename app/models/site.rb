class Site < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'sites'
  self.primary_key = 'site_id'

  def id = site_id

  # -----------------------------------------------------------------------------

  # find the site this app is running as, matching ENV['SITE_ENV_NAME'] to the site env handle
  # read once per process, as site attributes only change with a server restart
  def self.current
    @current ||= begin
      env_handle = HawthorneCore::AppConfig.site_env_name
      site = with_reading { find_by(env_handle:) }
      raise "No site found with env handle '#{env_handle}', check ENV['SITE_ENV_NAME']" unless site
      site.tap(&:readonly!)
    end
  end

  # -----------------------------------------------------------------------------

  def self.this_site_account_group = current.account_group

  def self.this_site_contact_email = current.contact_email

  def self.this_site_email_from_tagline = current.email_from_tagline

  # read live, not from current: edited in admin without a restart, and drives page cache invalidation
  def self.this_site_footer_version = with_reading { where(site_id: this_site_id).pick(:footer_version) }

  def self.this_site_has_checkout? = current.checkout

  # read live, not from current: edited in admin without a restart, and read when the header cache is rebuilt
  def self.this_site_header_announcement_attrs = with_reading { where(site_id: this_site_id).pick(:announcement_attrs) }

  # read live, not from current: edited in admin without a restart, and drives page cache invalidation
  def self.this_site_header_version = with_reading { where(site_id: this_site_id).pick(:header_version) }

  def self.this_site_id = current.site_id

  def self.this_site_mailer_send_welcome_template_id = current.mailer_send_welcome_template_id

  def self.this_site_name = current.handle

  def self.this_site_name_abbreviation = current.abbreviation

  # -----------------------------------------------------------------------------

end
