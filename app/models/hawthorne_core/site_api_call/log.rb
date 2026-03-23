# v3.0

module HawthorneCore::SiteApiCall::Log

  # -----------------------------------------------------------------------------

  MAILER_SEND = HawthorneCore::SiteApiType.mailer_send_id

  # ----------------------------------------------------------------------------- Mailer Send

  def self.mailer_send(api_url, api_url_note, api_values, api_response)
    success(MAILER_SEND, api_url, api_url_note, api_values, api_response)
  end

  def self.mailer_send_exception(api_url, api_url_note, api_values, exception_message)
    exception(MAILER_SEND, api_url, api_url_note, api_values, exception_message)
  end

  # -----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------- Core logger
  # -----------------------------------------------------------------------------

  def self.log(site_api_type_id, api_url, api_url_note, api_values, api_response, error_caught, error_message, exception_caught, exception_message)
    HawthorneCore::LogApiCallJob.perform_later(site_api_type_id, api_url, api_url_note, api_values, api_response, error_caught, error_message, exception_caught, exception_message)
  end

  # ----------------------------------------------------------------------------- Helpers

  # log an api call - via a job, so it does not delay the request
  def self.success(site_api_type_id, api_url, api_url_note, api_values, api_response)
    log(site_api_type_id, api_url, api_url_note, api_values, api_response, false, nil, false, nil)
  end

  # log a failed (error) api call - via a job, so it does not delay the request
  def self.failure(site_api_type_id, api_url, api_url_note, api_values, error_message)
    log(site_api_type_id, api_url, api_url_note, api_values, nil, true, error_message, false, nil)
  end

  # log a failed (exception) api call - via a job, so it does not delay the request
  def self.exception(site_api_type_id, api_url, api_url_note, api_values, exception_message)
    log(site_api_type_id, api_url, api_url_note, api_values, nil, false, nil, true, exception_message)
  end

  # -----------------------------------------------------------------------------

end