# v3.0XXX

class HawthorneCore::ApplicationController < ActionController::Base

  include HawthorneCore::Cache,
          HawthorneCore::Database,
          HawthorneCore::UserAuthentication,
          HawthorneCore::UserSession,
          HawthorneCore::UserValidation

  helper HawthorneCore::AwsHelper,
         HawthorneCore::CalcHelper,
         HawthorneCore::DateHelper,
         HawthorneCore::ImageHelper,
         HawthorneCore::ImageTypeHelper,
         HawthorneCore::LinkHelper,
         HawthorneCore::ProductHelper

  # ---------------------------------------------------------------------------

  # by default for all controllers, connect to a read database
  around_action :connect_to_read_database

  # -------------------------

  # set an attribute, denoting if the page is to be re-cached
  before_action :set_clear_cache_attr

  # set the sites header / footer versions in the cache
  before_action :set_site_header_footer_versions_in_cache

  # validate that the users session is captured in the database - if not previously validated
  before_action :validate_user_session, if: proc { !user_session_validated? }

  # create the users session - if it does not exist
  before_action :create_user_session, if: proc { !user_session? }

  # CORE ... determine if the user is signed in
  # before_action :is_signed_in

  # ---------------------------------------------------------------------------

end