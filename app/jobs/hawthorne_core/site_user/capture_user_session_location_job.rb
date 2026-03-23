# v3.0

# job to capture the site site_user sessions location
class HawthorneCore::SiteUser::CaptureUserSessionLocationJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(site_user_session_id)

    # return if not in production
    return unless Rails.env.production?

    # find the site site_user session
    # return if the session is not found, or if the ip address is not set
    site_user_session = HawthorneCore::SiteUserSession.find_by(site_user_session_id: site_user_session_id)
    return if site_user_session&.ip_address.blank?

    # find the location, via the GeocoderSvc service
    # return if the location is not returned
    location = HawthorneCore::Services::GeocoderSvc.find_location_by_ip_address(site_user_session.ip_address)
    return unless location

    # set the location into the site site_user session
    ActiveRecordBase.connected_to(role: :writing) do
      site_user_session.update!(location.slice(:city, :region, :country, :postal))
    end

  end

end