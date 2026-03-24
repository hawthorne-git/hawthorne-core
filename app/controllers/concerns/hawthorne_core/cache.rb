# v3.0

module HawthorneCore::Cache
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the pages cache should be cleared
    # when true, any cached segments (page / action / fragment) are expired
    def clear_cache? = params.key?(:cc)

    # -------------------------

    # set an attribute, denoting if the page is to be re-cached
    def set_clear_cache_attr
      @clear_cache = clear_cache?
    end

    # ---------------------------------------------------------------------------

    # set the sites header / footer versions in the cache, if needed
    def set_site_header_footer_versions_in_cache
      if @clear_cache || !Rails.cache.exist?(:header_version) || !Rails.cache.exist?(:footer_version)
        Rails.cache.write(:header_version, HawthorneCore::Site.header_version, expires_in: 1.month)
        Rails.cache.write(:footer_version, HawthorneCore::Site.footer_version, expires_in: 1.month)
      end
    end

    # ---------------------------------------------------------------------------

    # create the cache key wither header and footer versions - used for page / action caches
    # ex cache key: fabric-collection-controller-index-243
    # ex cache key with header and footer versions: fabric-collection-controller-index-243-h1-f1
    def cache_key_with_header_footer_versions(cache_key)
      header_version = Rails.cache.read(:header_version) || 0
      footer_version = Rails.cache.read(:footer_version) || 0
      "#{cache_key}-h#{header_version}-f#{footer_version}"
    end

    # ---------------------------------------------------------------------------

  end

end