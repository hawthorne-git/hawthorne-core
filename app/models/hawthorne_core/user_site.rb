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

end