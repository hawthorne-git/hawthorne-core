# v3.0

class HawthorneCore::SiteUserSession < HawthorneCore::ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'site_user_sessions'

  # -----------------------------------------------------------------------------

  def id = site_user_session_id

  # -----------------------------------------------------------------------------

  # creates a record ... using the request
  def self.create_record(request, site_user_id)
    with_writing do
      create(
        token: SecureRandom.alphanumeric(30),
        site_id: HawthorneCore::Site.this_site_id,
        site_user_id: site_user_id,
        ip_address: request.env['HTTP_CF_CONNECTING_IP'],
        http_referer: request.env['HTTP_REFERER'],
        http_user_agent: request.env['HTTP_USER_AGENT'],
        opening_url: request.fullpath
      )
    end
  end

  # -----------------------------------------------------------------------------

  # determine if a record exists with the token
  def self.record_exists_with_token?(token)
    exists?(token: token)
  end

  # -----------------------------------------------------------------------------

end