# v3.0XXX

module HawthorneCore::UserAuthentication
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the site_user is signed in
    def signed_in?

      # if the site_user is found in the session,
      # set the site_user as signed in and return
      (@signed_in = true; return) if session[:site_user_id].present?

      # if the site_user is not found in the session, and trying to find the site_user via their cookie token is already attempted,
      # set the site_user as not signed in and return
      (@signed_in = false; return) if session[:find_via_cookie_attempted].present?

      @signed_in = false
      return if true

      # find the site_user id for the site site_user session, by their cookie token
      user_id = Core::SiteUserSession.
        where(token: cookies[:user_session_token]).
        where(keep_signed_in: true).
        pluck(:site_user_id)[0]

      # if the site_user is present ...
      # set the site_user into the session and log in the site_user (via cookie)
      if user_id.present?
        session[:site_user_id] = user_id
        Core::UserAction.log_sign_in_cookie_action(user_id, request.remote_ip, cookies[:user_session_token])
      end

      # note that trying to find the site_user via their cookie has been attempted
      session[:find_via_cookie_attempted] = true

      # determine if the site_user is signed in (via cookie)
      @signed_in = session[:site_user_id].present?

    end

    # ---------------------------------------------------------------------------

  end

end