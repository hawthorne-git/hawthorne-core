# v3.0XXX

module HawthorneCore::UserAuthentication
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the user is signed in
    def signed_in?

      # if the user is found in the session,
      # set the user as signed in and return
      (@signed_in = true; return) if session[:site_user_id].present?

      # if the user is not found in the session, and trying to find the user via their cookie token is already attempted,
      # set the user as not signed in and return
      (@signed_in = false; return) if session[:find_via_cookie_attempted].present?

      @signed_in = false
      return if true

      # find the user id for the site user session, by their cookie token
      user_id = Core::UserSession.
        where(token: cookies[:user_session_token]).
        where(keep_signed_in: true).
        pluck(:site_user_id)[0]

      # if the user is present ...
      # set the user into the session and log in the user (via cookie)
      if user_id.present?
        session[:site_user_id] = user_id
        Core::UserAction.log_sign_in_cookie_action(user_id, request.remote_ip, cookies[:user_session_token])
      end

      # note that trying to find the user via their cookie has been attempted
      session[:find_via_cookie_attempted] = true

      # determine if the user is signed in (via cookie)
      @signed_in = session[:site_user_id].present?

    end

    # ---------------------------------------------------------------------------

  end

end