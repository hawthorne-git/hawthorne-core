# v3.0

# job to capture the user session location
class HawthorneCore::User::CaptureUserSessionLocationJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(user_session_id)

    # return if not in production
    return unless Rails.env.production?

    # find the user session
    # return if the session is not found, or if the ip address is not set
    user_session = HawthorneCore::UserSession.find_by(user_session_id: user_session_id)
    return if user_session&.ip_address.blank?

    # find the location, via the GeocoderSvc service
    # return if the location is not returned
    location = HawthorneCore::Services::GeocoderSvc.find_location_by_ip_address(user_session.ip_address)
    return unless location

    # set the location into the user session
    ActiveRecordBaseLog.with_writing { user_session.update!(location.slice(:city, :region, :country)) }

  end

end