module HawthorneCore::SiteAuthentication
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the site is locked
    def site_locked? = HawthorneCore::AppConfig.site_locked?

    # ---------------------------------------------------------------------------

    # determine if the site has been unlocked
    def site_unlocked? = session[:SITE_UNLOCKED]

    # ---------------------------------------------------------------------------

    # verify the site key ... if it matches, unlock the site for this session, otherwise send the user to google
    def verify_site_key
      site_lock_key = params[:site_lock_key].to_s
      if ActiveSupport::SecurityUtils.secure_compare(site_lock_key, HawthorneCore::AppConfig.site_lock_key)
        session[:SITE_UNLOCKED] = true
      else
        redirect_to 'https://www.google.com', allow_other_host: true
      end
    end

    # ---------------------------------------------------------------------------

  end

end