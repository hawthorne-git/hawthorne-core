class HawthorneCore::FlaggedHttpUserAgent < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'flagged_http_user_agents'
  self.primary_key = 'flagged_http_user_agent_id'

  def id = flagged_http_user_agent_id

  # -----------------------------------------------------------------------------

end
