class HawthorneCore::FlaggedIp < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'flagged_ips'
  self.primary_key = 'flagged_ip_id'

  def id = flagged_ip_id

  # -----------------------------------------------------------------------------

end