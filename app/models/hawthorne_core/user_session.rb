# v3.0

class HawthorneCore::UserSession < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'user_sessions'

  def id = user_session_id

  # -----------------------------------------------------------------------------

  # creates a record ... using the request
  def self.create_record(user_id, request)
    create!(
      token: SecureRandom.alphanumeric(30),
      user_id: user_id,
      ip_address: request.remote_ip,
      http_referer: request.env['HTTP_REFERER'],
      http_user_agent: request.env['HTTP_USER_AGENT'],
      opening_url: request.fullpath
    )
  end

  # -----------------------------------------------------------------------------

  # determine if a record exists with the token
  def self.record_exists_with_token?(token) = exists?(token: token)

  # -----------------------------------------------------------------------------

end