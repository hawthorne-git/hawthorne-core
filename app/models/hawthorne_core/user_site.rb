# v3.0

class HawthorneCore::UserSite < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasSiteId,
          HawthorneCore::UserSite::DeleteAccount,
          HawthorneCore::UserSite::Email,
          HawthorneCore::UserSite::PhoneNumber,
          HawthorneCore::UserSite::SignIn


  # -----------------------------------------------------------------------------

  self.table_name = 'user_sites'

  def id = user_site_id

  # -----------------------------------------------------------------------------


  def first_sign_in? = sign_in_count.zero?

  # ------------------------

  # log the user site sign-in
  def self.log_site_sign_in(user_id:, keep_signed_in:)
    signed_in_at = Time.current
    user_site = find_by(site_id: HawthorneCore::Site.this_site_id, user_id:)
    user_site.first_signed_in_at = signed_in_at if user_site.first_sign_in?
    user_site.last_signed_in_at = signed_in_at
    user_site.keep_signed_in = keep_signed_in
    user_site.sign_in_count += 1
    user_site.save!
  end

  # log the user site sign-out,
  # update keep signed in flag to FALSE - forcing the user to sign-in at next visit
  def self.log_site_sign_out(user_id)
    find_by(site_id: HawthorneCore::Site.this_site_id, user_id:)&.update_columns(keep_signed_in: false)
  end

  # -----------------------------------------------------------------------------

end