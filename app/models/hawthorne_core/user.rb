# v3.0

class HawthorneCore::User < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::User::Email,
          HawthorneCore::User::Name,
          HawthorneCore::User::PaymentMethods,
          HawthorneCore::User::PhoneNumber,
          HawthorneCore::User::Code,
          HawthorneCore::User::SingleSignOn,
          HawthorneCore::User::SiteAccess

  # -----------------------------------------------------------------------------

  self.table_name = 'users'

  def id = user_id

  # -----------------------------------------------------------------------------

  # find the users site record
  def user_site = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

  # -----------------------------------------------------------------------------

  # determine if a specific user id is deleted
  def self.deleted?(user_id:) = exists?(user_id:, deleted: true)

  # -----------------------------------------------------------------------------

end