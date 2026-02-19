# v3.0XXX

class HawthorneCore::ApplicationController < ActionController::Base

  include HawthorneCore::Cache,
          HawthorneCore::Database,
          HawthorneCore::User,
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

  # CORE ... validate that the users (cookie) session is found in the database - only call if the token is blank
  # before_action :validate_site_user_session, if: proc { session[:site_user_token_validated].blank? }

  # CORE ... determine if the users (cookie) session is created - only call if the token is blank
  # before_action :create_site_user_session, if: proc { cookies[:site_user_token].blank? }

  # CORE ... determine if the user is signed in
  # before_action :is_signed_in



  # ---------------------------------------------------------------------------

end