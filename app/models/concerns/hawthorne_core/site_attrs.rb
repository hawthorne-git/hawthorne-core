# v3.0

module HawthorneCore::SiteAttrs
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # for code ease, define the site id
    def self.site_id = HawthorneCore::Site.this_site_id

    # for code ease, define the site sharing scope
    def self.site_sharing_scope = HawthorneCore::Site.this_site_sharing_scope

    # ---------------------------------------------------------------------------------

  end

end