# v3.0

module HawthorneCore::HasSiteId
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    before_validation :set_site_id, on: :create

    # ---------------------------------------------------------------------------------

    private

    def set_site_id
      self.site_id ||= HawthorneCore::Site.this_site_id
    end

    # ---------------------------------------------------------------------------------

  end

end