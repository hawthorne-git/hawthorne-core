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

  # create the user record, returning it ... and log that the user was created on this site
  def self.create_record(email_address, ip_address, user_session_token)
    user = create!(email_address: email_address)
    user.log_site_access_for_new_user
    HawthorneCore::UserAction::Log.account_created(user.id, { email_address: email_address }, ip_address, user_session_token)
    user
  end

  # -----------------------------------------------------------------------------

end