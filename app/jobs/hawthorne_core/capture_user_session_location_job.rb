# v3.0

# job to capture the user sessions location
class HawthorneCore::CaptureUserSessionLocationJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(site_user_session_id)
    HawthorneCore::Services::GeocoderSvc.set_user_session_location(site_user_session_id)
  end

end