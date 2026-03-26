# v3.0XXX

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

      # if the user is present ... and if the user opted to keep as signed in
      # set the user as signed in and reset the cookie expiration
      if user_id.present?
        keep_signed_in = HawthorneCore::UserSite.where(site_id: HawthorneCore::Site.this_site_id, user_id: user_id).pick(:keep_signed_in)
        if keep_signed_in
          session[:user_id] = user_id
          cookies[:user_session_token] = { value: cookies[:user_session_token], expires: 1.month.from_now, httponly: true, secure: Rails.env.production?, same_site: :lax }
          HawthorneCore::UserAction::Log.sign_in_via_cookie(user_id, { user_session_token: cookies[:user_session_token] })
        end
      end

      # note that trying to find the user via their cookie has been attempted
      session[:find_via_cookie_attempted] = true

      # determine if the user is signed in
      @signed_in = session[:user_id].present?

    end

    # ---------------------------------------------------------------------------

  end

end