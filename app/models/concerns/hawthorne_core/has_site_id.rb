# v3.0

module HawthorneCore::HasSiteId
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # before creating a record,
    # set the records site id attribute
    before_validation :set_site_id, on: :create

    # ---------------------------------------------------------------------------------

    private

    # set the site id
    def set_site_id
      self.site_id = HawthorneCore::Site.this_site_id
    end

    # ---------------------------------------------------------------------------------

  end

end