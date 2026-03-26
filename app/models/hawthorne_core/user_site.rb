# v3.0

class HawthorneCore::UserSite < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'user_sites'

  def id = user_site_id

  # -----------------------------------------------------------------------------

  def self.user_access_exist?(user_id) = exists?(site_id: HawthorneCore::Site.this_site_id, user_id: user_id)

  def self.first_sign_in?(user_id) = exists?(site_id: HawthorneCore::Site.this_site_id, user_id: user_id, sign_in_count: 0)

  def first_sign_in? = sign_in_count.zero?

  # -----------------------------------------------------------------------------

  # create a user site access record, for a new user
  def self.log_site_access_for_new_user(user_id)
    create!(user_id: user_id, user_created_on_site: true)
  end

  # create a user site access record, for a known user, if the user has never accessed this site
  def self.log_site_access_for_known_user(user_id)
    create!(user_id: user_id) unless user_access_exist?(user_id)
  end

  # log the user site sign-in
  def self.log_site_sign_in(user_id)
    user_site = find_by(site_id: HawthorneCore::Site.this_site_id, user_id: user_id)
    if user_site.first_sign_in?
      user_site.first_signed_in_at = user_site.last_signed_in_at = Time.current
      user_site.sign_in_count = 1
      user_site.save!
    else
      user_site.last_signed_in_at = Time.current
      user_site.sign_in_count = (user_site.sign_in_count + 1)
      user_site.save!
    end
  end

  # -----------------------------------------------------------------------------

end