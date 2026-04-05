# v3.0

class HawthorneCore::User < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasToken,
          HawthorneCore::User::EmailVerification,
          HawthorneCore::User::PinVerification,
          HawthorneCore::User::SingleSignOn,
          HawthorneCore::User::SiteAccess

  # -----------------------------------------------------------------------------

  self.table_name = 'users'

  def id = user_id

  # -----------------------------------------------------------------------------

end