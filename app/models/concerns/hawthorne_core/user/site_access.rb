# v3.0

module HawthorneCore::User::SiteAccess
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # log that a new user has accessed the site
    def log_site_access_for_new_user  = HawthorneCore::UserSite.log_site_access_for_new_user(id)

    # log that an existing user has accessed the site
    def log_site_access_for_user = HawthorneCore::UserSite.log_site_access_for_user(id)

    # -----------------------------------------------------------------------------

  end

end