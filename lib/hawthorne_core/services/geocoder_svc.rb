# v3.0

class HawthorneCore::Services::GeocoderSvc

  # ----------------------------------------------------------------

  # find a location (city, region, country) by an ip address
  def self.find_location_by_ip_address(ip_address)

    # return if the ip address is not set
    return if ip_address.blank?

    # find the location
    # return if the location is not set
    # TODO: treat this like an API call ... log it
    # TODO: catch exceptions
    location = Geocoder.search(ip_address).first
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