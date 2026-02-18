module HawthorneCore::User
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # create the users site session, defined by a token
    # this method is called as a before action in the application controller IF the session variable site_user_token is blank
    def create_site_user_session
      return if Core::SiteUserSession.bot?(request.env['HTTP_REFERER'], request.env['HTTP_USER_AGENT'], request.env['HTTP_CF_CONNECTING_IP'])
      HawthorneCore::ActiveRecordBase.connected_to(role: :writing) do
        site_user_session = Core::SiteUserSession.create(
          token: [*('a'..'z'), *('A'..'Z'), *('0'..'9')].shuffle[0, 30].join,
          site_id: Core::Site.this_site_id,
          site_user_id: session[:user_id],
          ip_address: request.env['HTTP_CF_CONNECTING_IP'],
          http_referer: request.env['HTTP_REFERER'],
          http_user_agent: request.env['HTTP_USER_AGENT'],
          opening_url: request.fullpath
        )
        cookies[:site_user_token] = { value: site_user_session.token, expires: 1.month, same_site: :strict }
        CoreJobs::User::CaptureSiteUserSessionLocationJob.perform_later(site_user_session.site_user_session_id)
      end
    end

    # ---------------------------------------------------------------------------

    # determine if the user is signed in
    def is_signed_in

      # if the user is found in the session,
      # set the user as signed in and return
      (@signed_in = true; return) if session[:user_id].present?

      # if the user is not found in the session, and trying to find the user via their cookie token is already attempted,
      # set the user as not signed in and return
      (@signed_in = false; return) if session[:find_via_cookie_attempted].present?

      # find the user id for the site user session, by their cookie token
      user_id = Core::SiteUserSession.
        where(token: cookies[:site_user_token]).
        where(keep_signed_in: true).
        pluck(:site_user_id)[0]

      # if the user is present ...
      # set the user into the session and log in the user (via cookie)
      if user_id.present?
        session[:user_id] = user_id
        Core::UserAction.log_sign_in_cookie_action(user_id, request.remote_ip, cookies[:site_user_token])
      end

      # note that trying to find the user via their cookie has been attempted
      session[:find_via_cookie_attempted] = true

      # determine if the user is signed in (via cookie)
      @signed_in = session[:user_id].present?

    end

    # ---------------------------------------------------------------------------

    # validate the sites users session
    def validate_site_user_session

      # return if there does not exist a site user token - there is nothing to validate
      return if cookies[:site_user_token].blank?

      # using the primary (write) database ...
      # if the site user session if found, set the session attribute to true - it is validated
      # else set the site user token to nil, which will force creating a new token
      HawthorneCore::ActiveRecordBase.connected_to(role: :writing) do
        if Core::SiteUserSession.find_by(token: cookies[:site_user_token]).present?
          session[:site_user_token_validated] = true
        else
          cookies[:site_user_token] = nil
        end
      end

    end

    # ---------------------------------------------------------------------------

  end

end