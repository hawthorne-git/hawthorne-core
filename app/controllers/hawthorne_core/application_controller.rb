# v3.0

class HawthorneCore::ApplicationController < ::ApplicationController

  include HawthorneCore::Cache,
          HawthorneCore::Errors,
          HawthorneCore::UserAuthentication,
          HawthorneCore::UserSessionIssuer

  # ---------------------------------------------------------------------------

  # only support 'modern' browsers
  allow_browser versions: :modern

  # ---------------------------------------------------------------------------

  # set an attribute, noting if the page is to be re-cached
  before_action :set_clear_cache_attr

  # set the sites header / footer versions in the cache
  before_action :set_site_header_footer_versions_in_cache

  # verify that the users session is captured in the database - if not previously verified
  before_action :verify_user_session, if: proc { !user_session_verified? }

  # create the users session - if it does not exist
  before_action :create_user_session, if: proc { !user_session? }

  # determine if the user is signed in
  before_action :signed_in?

  # ---------------------------------------------------------------------------

  # changes to the importmap will invalidate the etag for HTML responses - rails v8 default
  stale_when_importmap_changes

  # ---------------------------------------------------------------------------

  # for code ease, define the site id
  def site_id = HawthorneCore::Site.this_site_id

  # for code ease, define the user id
  def user_id = session[:user_id]

  # ---------------------------------------------------------------------------

end