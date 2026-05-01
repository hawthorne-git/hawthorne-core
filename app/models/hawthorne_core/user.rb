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

  # find the users site record
  def user_site = HawthorneCore::UserSite.select(:user_site_id, :user_id).find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

  # -----------------------------------------------------------------------------

  # determine if a user exists with email for site sharing scope
  def self.exists_with_email?(email:) = active.exists?(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)

  # determine if a user exists with token
  def self.exists_with_token?(token:) = active.exists?(token:)

  # get the token for a user id
  def self.token_for_user_id(user_id:) = where(user_id:).pick(:token)

  # get the users id for an email with the site sharing scope
  def self.user_id_for_email(email:) = active.where(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope).pick(:user_id)

  # get the users id for a token
  def self.user_id_for_token(token:) = where(token:).pick(:user_id)

  # -----------------------------------------------------------------------------

  # find (or create) the user
  def self.find_or_create(email:)

    # if a user exists with the email - create a site record, if needed
    # else create the user and their site record
    if exists_with_email?(email:)
      user_id = user_id_for_email(email:)
      HawthorneCore::UserSite.create!(user_id:) unless HawthorneCore::UserSite.user_exist?(user_id:)
    else
      user = create!(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)
      HawthorneCore::UserSite.create!(user_id: user.id, user_created_on_site: true)
      HawthorneCore::UserAction::Log.account_created(user_id: user.id, note: { email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope })
    end

    # return the user
    active.find_by(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)

  end

  # -----------------------------------------------------------------------------

end