# v3.0

module HawthorneCore::UserAuthentication
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the user is signed in
    def signed_in?

      # if the user is found in the session,
      # set the user as signed in and return
      (@signed_in = true; return) if session[:user_id].present?

      # if the user is not found in the session, and previously attempted to find the user via their cookie ...
      # set the user as not signed in and return
      (@signed_in = false; return) if session[:find_via_cookie_attempted].present?

      # at this point the user is NOT signed in,
      # and finding the user via their cookie (user session) has not been attempted

      # find if a user id is attached to the cookie (user session)
      user_id = HawthorneCore::UserSession.where(token: cookies[:user_session_token]).pick(:user_id)

      # if the user is present (and not deleted) ... and if the user opted to keep as signed in
      # set the user as signed in and reset the cookie expiration
      if user_id.present? & !HawthorneCore::User.deleted?(user_id:)
        keep_signed_in = HawthorneCore::UserSite.where(site_id: HawthorneCore::Site.this_site_id, user_id:).pick(:keep_signed_in)
        if keep_signed_in
          session[:user_id] = user_id
          cookies[:user_session_token] = { value: cookies[:user_session_token], expires: 1.month.from_now, httponly: true, secure: Rails.env.production?, same_site: :lax }
          HawthorneCore::UserAction::Log.sign_in_via_cookie(user_id:, note: { user_session_token: cookies[:user_session_token] })
        end
      end

      # note that trying to find the user via their cookie has been attempted
      session[:find_via_cookie_attempted] = true

      # determine if the user is signed in
      @signed_in = session[:user_id].present?

    end

    # ---------------------------------------------------------------------------

    # verify that the session user exists as an active user
    # if not - reset the session and redirect the user to the sites home page
    def active_user?
      return if HawthorneCore::User.active.exists?(user_id: session[:user_id])
      reset_session
      redirect_to '/'
    end

    # ----------------------

    # verifies that the site user is signed in
    # if not - the user is signed out, the user is redirected to the sign-in page
    def user_signed_in?
      redirect_to sign_in_path unless @signed_in
    end

    # ----------------------

    # verifies that the site user is signed out
    # if not - the user is signed in, the user is redirected to their account page
    def user_signed_out?
      redirect_to account_path if @signed_in
    end

    # ---------------------------------------------------------------------------

    # set the users id, ip and user session token into the request context
    def set_request_context
      HawthorneCore::RequestContext.set(user_id: session[:user_id], ip: request.remote_ip, user_session_token: cookies[:user_session_token])
    end

    # ----------------------

    # clear the users id, ip and user session token from the request context
    def clear_request_context
      HawthorneCore::RequestContext.clear
    end

    # ---------------------------------------------------------------------------

  end

end