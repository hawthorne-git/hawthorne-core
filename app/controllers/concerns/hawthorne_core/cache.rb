module HawthorneCore::Cache
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # set each of the clear cache attributes as variables to be used throughout the request
    def set_clear_cache_attributes
      @clear_page_cache = clear_page_cache?
      @clear_action_cache = clear_action_cache?
      @clear_action_cache_attrs = clear_action_cache_attrs?
      @clear_fragment_cache = clear_fragment_cache?
    end

    # ---------------------------------------------------------------------------

    # determine if the pages cache should be cleared
    # when true the entire page is re-cached
    # 'cc = t' was originally denoted, but 'refresh = now' was added for ease of use
    def clear_page_cache?
      (params[:cc]&.downcase == 't') || (params[:refresh]&.downcase == 'now')
    end

    # ---------------------------------------------------------------------------

    # determine if the rails action cache should be cleared - this excludes header / footer blocks
    # when true the rails action is re-cached
    # this is also true if the page cache is to be cleared
    def clear_action_cache?
      clear_page_cache? || (params[:cac]&.downcase == 't')
    end

    # ---------------------------------------------------------------------------

    # determine if the rails action cache attributes should be cleared
    # on specific pages the rails action attributes are cached, then checked on each page, to determine if a re-cache is needed
    # example is
    def clear_action_cache_attrs?
      params[:cac_attrs]&.downcase == 'yes'
    end

    # ---------------------------------------------------------------------------

    # determine if the rails fragment cache should be cleared
    # a fragment can be part of a controller (db call), but most likely in the view (displaying an image)
    # when true all fragment portions of the page are re-cached
    # this is also true if the page / action cache is to be cleared
    def clear_fragment_cache?
      clear_action_cache? || (params[:cfc]&.downcase == 't')
    end

    # ---------------------------------------------------------------------------
    # ---------------------------------------------------------------------------
    # ---------------------------------------------------------------------------

    # reset the sites header / footer versions in the cache, if needed
    def header_footer_versions
      Rails.cache.write(:header_version, Core::Site.this_site_header_version, expires_in: 1.month) if @clear_fragment_cache || Rails.cache.read(:header_version).nil?
      Rails.cache.write(:footer_version, Core::Site.this_site_footer_version, expires_in: 1.month) if @clear_fragment_cache || Rails.cache.read(:footer_version).nil?
    end

    # create the action cache key wither header / footer versions
    def action_cache_with_header_footer_versions(cache_key)
      cache_key + '-h' + Rails.cache.read(:header_version).to_s + '-f' + Rails.cache.read(:footer_version).to_s
    end

    # ---------------------------------------------------------------------------
    # ---------------------------------------------------------------------------
    # ---------------------------------------------------------------------------

  end

end