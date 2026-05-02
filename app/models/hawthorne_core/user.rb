# v3.0

class HawthorneCore::User < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::User::Code,
          HawthorneCore::User::DeleteAccount,
          HawthorneCore::User::Email,
          HawthorneCore::User::Name,
          HawthorneCore::User::PaymentMethods,
          HawthorneCore::User::PhoneNumber,
          HawthorneCore::User::SignInOut

  # -----------------------------------------------------------------------------

  self.table_name = 'users'

  def id = user_id

  # -----------------------------------------------------------------------------

  # for code ease, define the site id
  def site_id = HawthorneCore::Site.this_site_id
  def self.site_id = HawthorneCore::Site.this_site_id

  # for code ease, define the site sharing scope
  def self.site_sharing_scope = HawthorneCore::Site.this_site_sharing_scope

  # -----------------------------------------------------------------------------

  # find the users site record
  def user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)
  def self.user_site(user_id:) = HawthorneCore::UserSite.find_by(user_id:, site_id:)

  # -----------------------------------------------------------------------------

  # determine if an active user exists with this email for site sharing scope
  def self.email_exists?(email:) = active.exists?(email:, site_sharing_scope:)

  # determine if an active user exists with this token
  def self.token_exists?(token:) = active.exists?(token:)

  # ----------------------

  # find the token, by this user id
  def self.token(user_id:) = active.where(user_id:).pick(:token)

  # find the user id, by this email with site sharing scope
  def self.user_id_by_email(email:) = active.where(email:, site_sharing_scope:).pick(:user_id)

  # find the user id, by this token
  def self.user_id_by_token(token:) = active.where(token:).pick(:user_id)

  # -----------------------------------------------------------------------------

  # find (or create) the user
  def self.find_or_create(email:)

    # if a user exists with the email - create a site record, if needed
    # else create the user and their site record
    if email_exists?(email:)
      user_id = user_id_by_email(email:)
      HawthorneCore::UserSite.create!(user_id:) unless HawthorneCore::UserSite.user_exist?(user_id:)
    else
      user = create!(email:, site_sharing_scope:)
      HawthorneCore::UserSite.create!(user_id: user.id, user_created_on_site: true)
      HawthorneCore::UserAction::Log.account_created(user_id: user.id, note: { email:, site_sharing_scope: })
    end

    # return the user
    find_by(email:, site_sharing_scope:)

  end
  
  # -----------------------------------------------------------------------------

end