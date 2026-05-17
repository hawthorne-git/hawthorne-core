class HawthorneCore::Services::GeocoderSvc

  # ----------------------------------------------------------------

  # find a location (city, region, country) by an ip
  def self.find_location_by_ip(ip:)

    # return if the ip is not set
    return if ip.blank?

    # find the location
    # return if the location is not set
    location = Geocoder.search(ip).first
    return unless location

    # return the location (as a hash)
    {
      city: location.city,
      region: location.region,
      country: location.country
    }

  end

  # ----------------------------------------------------------------

end