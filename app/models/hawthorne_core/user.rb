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

  # determine if a specific user id is deleted
  def self.deleted?(user_id:) = exists?(user_id:, deleted: true)

  # -----------------------------------------------------------------------------

end