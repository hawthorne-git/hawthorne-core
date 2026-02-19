# v3.0

module HawthorneCore::Site::Attrs
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # get the sites header version
    def self.header_version
      where(site_id: HawthorneCore::Site.this_site_id).pick(:header_version)
    end

    # -------------------------

    # get the sites footer version
    def self.footer_version
      where(site_id: HawthorneCore::Site.this_site_id).pick(:footer_version)
    end

    # -----------------------------------------------------------------------------

  end

end