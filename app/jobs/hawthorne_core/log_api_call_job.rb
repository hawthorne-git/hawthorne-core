# v3.0

# log an api call
class HawthorneCore::LogApiCallJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(site_api_type_id, api_url, api_url_note, api_values, api_response, error_caught, error_message, exception_caught, exception_message)

    HawthorneCore::ActiveRecordBase.with_writing do
      HawthorneCore::SiteApiCall.create!(
        site_id: HawthorneCore::Site.this_site_id,
        site_api_type_id: site_api_type_id,
        api_url: api_url,
        api_url_note: api_url_note,
        api_values: api_values&.to_s,
        api_response: api_response&.to_s,
        error_caught: error_caught,
        error_message: error_message&.to_s,
        exception_caught: exception_caught,
        exception_message: exception_message&.to_s
      )
    end

  end

end