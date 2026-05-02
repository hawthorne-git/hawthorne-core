# v3.0

class HawthorneCore::UserSite < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasSiteId,
          HawthorneCore::UserSite::DeleteAccount,
          HawthorneCore::UserSite::Email,
          HawthorneCore::UserSite::PhoneNumber,
          HawthorneCore::UserSite::SignInOut


  # -----------------------------------------------------------------------------

  self.table_name = 'user_sites'

  def id = user_site_id

  # -----------------------------------------------------------------------------

  # for code ease, define the site id
  def self.site_id = HawthorneCore::Site.this_site_id

  # -----------------------------------------------------------------------------

  # determine if a user exists for this site
  def self.user_exist?(user_id:) = exists?(user_id:, site_id:)

  # -----------------------------------------------------------------------------

end