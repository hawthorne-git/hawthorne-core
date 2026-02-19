# v3.0

# Geocoder service
class HawthorneCore::Services::GeocoderSvc

  # ----------------------------------------------------------------

  def self.set_user_session_location(site_user_session_id)

    # return if not in production
    return unless Rails.env.production?

    # find the site user session
    # return if the session is not found, or if the ip address is not set
    site_user_session = HawthorneCore::SiteUserSession.find_by(site_user_session_id: site_user_session_id)
    return if site_user_session&.ip_address.blank?

    # find the location by the ip address
    # return if a location is not returned
    location = Geocoder.search(site_user_session.ip_address)&.first
    return unless location

    # set the location into the site user session
    ActiveRecordBase.connected_to(role: :writing) do
      site_user_session.update(
        city: location.city,
        region: location.region,
        country: location.country,
        postal: location.postal
      )
    end

  end

  # ----------------------------------------------------------------

end