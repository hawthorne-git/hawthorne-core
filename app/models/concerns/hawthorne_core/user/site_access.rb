# v3.0

module HawthorneCore::User::SiteAccess
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def first_sign_in_on_site? = HawthorneCore::UserSite.first_sign_in?(id)

    # -----------------------------------------------------------------------------

    def log_site_access_for_new_user = HawthorneCore::UserSite.log_site_access_for_new_user(id)

    def log_site_access_for_known_user = HawthorneCore::UserSite.log_site_access_for_known_user(id)

    def log_site_sign_in(keep_signed_in) = HawthorneCore::UserSite.log_site_sign_in(id, keep_signed_in)

    # -----------------------------------------------------------------------------

  end

end