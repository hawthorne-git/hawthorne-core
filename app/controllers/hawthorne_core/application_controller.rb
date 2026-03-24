# v3.0XXX

class HawthorneCore::ApplicationController < ::ApplicationController

  include HawthorneCore::Cache,
          HawthorneCore::UserAuthentication,
          HawthorneCore::UserSessionIssuer,
          HawthorneCore::UserValidation

  # ---------------------------------------------------------------------------

  # set an attribute, denoting if the page is to be re-cached
  before_action :set_clear_cache_attr

  # set the sites header / footer versions in the cache
  before_action :set_site_header_footer_versions_in_cache

  # validate that the users session is captured in the database - if not previously validated
  before_action :validate_user_session, if: proc { !user_session_validated? }

  # create the users session - if it does not exist
  before_action :create_user_session, if: proc { !user_session? }

  # CORE ... determine if the user is signed in
  # TODO
  #before_action :signed_in?

  # ---------------------------------------------------------------------------

end