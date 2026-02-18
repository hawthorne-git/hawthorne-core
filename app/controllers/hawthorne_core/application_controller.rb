# v3.0XXX

module HawthorneCore

  class ApplicationController < ActionController::Base

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

    # connect to a random read database
    #around_action :connect_to_read_database

    # CORE ... define clear cache attributes
    #before_action :set_clear_cache_attributes

    # CORE ... validate that the users (cookie) session is found in the database - only call if the token is blank
    #before_action :validate_site_user_session, if: proc { session[:site_user_token_validated].blank? }

    # CORE ... determine if the users (cookie) session is created - only call if the token is blank
    #before_action :create_site_user_session, if: proc { cookies[:site_user_token].blank? }

    # CORE ... determine if the user is signed in
    #before_action :is_signed_in

    # CORE ... set header / footer versions
    #before_action :header_footer_versions

    # ---------------------------------------------------------------------------

  end

end