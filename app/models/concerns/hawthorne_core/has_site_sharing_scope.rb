# v3.0

module HawthorneCore::HasSiteSharingScope
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # before creating a record, set the records site sharing scope attribute
    before_validation :set_site_sharing_scope, on: :create

    # ---------------------------------------------------------------------------------

    private

    # set the site id
    def set_site_sharing_scope
      self.site_sharing_scope = HawthorneCore::Site.this_site_sharing_scope
    end

    # ---------------------------------------------------------------------------------

  end

end