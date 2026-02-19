# v3.0

module HawthorneCore::UserSession
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the users session exists
    def user_session?
      cookies.key?(:user_session_token)
    end

    # determine if the users session has been validated
    def user_session_validated?
      session[:user_session_validated]
    end

    # ---------------------------------------------------------------------------

    # create the users session - if not a bot
    def create_user_session

      # return, and do not create a user session if the request is determined to be a bot
      return if HawthorneCore::BotHelper.bot?(request)

      # create the user session
      site_user_session = HawthorneCore::SiteUserSession.create_record(request, session[:user_id])

      # set the user session token (as a cookie), and mark the session as validated
      cookies[:user_session_token] = { value: site_user_session.token, expires: 1.month, same_site: :strict }
      session[:user_session_validated] = true

      # kick off a job to capture the users session location
      HawthorneCore::CaptureUserSessionLocationJob.perform_later(site_user_session.id)

    end

    # ---------------------------------------------------------------------------

    # validate the users session
    # to be true ... a cookie defining the users session MUST exist, and this cookie value MUST exist in the database
    def validate_user_session

      # if a user session token does not exist as a cookie ...
      # set the user session as NOT validated and return
      unless cookies.key?(:user_session_token)
        session[:user_session_validated] = false
        return
      end

      # a user session token exists as a cookie ...

      #  if this token does NOT exist in the database ...
      #  set the user session as NOT validated, delete the cookie, and return
      unless HawthorneCore::SiteUserSession.record_exists_with_token?(cookies[:user_session_token])
        session[:user_session_validated] = false
        cookies.delete(:user_session_token)
        return
      end

      # the session is validated
      session[:user_session_validated] = true

    end

    # ---------------------------------------------------------------------------

  end

end