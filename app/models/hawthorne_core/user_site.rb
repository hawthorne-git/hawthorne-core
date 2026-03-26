# v3.0

class HawthorneCore::UserSite < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'user_sites'

  def id = user_site_id

  # -----------------------------------------------------------------------------

  def self.user_site_access_exist?(user_id) = exists?(site_id: HawthorneCore::Site.this_site_id, user_id: user_id)

  # -----------------------------------------------------------------------------

  # create a user site record for a new user
  def self.log_site_access_for_new_user(user_id)
    create!(user_id: user_id, user_created_on_site: true)
  end

  # create a user site record for a known user, if the user has never accessed the site
  def self.log_site_access_for_user(user_id)
    create!(user_id: user_id) unless user_site_access_exist?(user_id)
  end

  # -----------------------------------------------------------------------------

end