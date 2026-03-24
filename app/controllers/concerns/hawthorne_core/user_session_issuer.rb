# v3.0

module HawthorneCore::UserSessionIssuer
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the users session exists (as a cookie)
    def user_session? = cookies.key?(:user_session_token)

    # determine if the users session has been validated
    def user_session_validated? = session[:user_session_validated]

    # ---------------------------------------------------------------------------

    # create the users session - if not a bot
    def create_user_session

      # return, and do not create a user session if the request is determined to be a bot
      return if HawthorneCore::BotHelper.bot?(request)

      # create the user session
      user_session = HawthorneCore::UserSession.create_record(session[:user_id], request)

      # set the user session token (as a cookie), and mark the session as validated
      cookies[:user_session_token] = { value: user_session.token, expires: 1.month, same_site: :strict }
      session[:user_session_validated] = true

      # kick off a job to capture the users session location
      HawthorneCore::User::CaptureUserSessionLocationJob.perform_later(user_session.id)

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
      unless HawthorneCore::UserSession.record_exists_with_token?(cookies[:user_session_token])
        session[:user_session_validated] = false
        cookies.delete(:user_session_token)
        return
      end

      # the user session is validated
      session[:user_session_validated] = true

    end

    # ---------------------------------------------------------------------------

  end

end