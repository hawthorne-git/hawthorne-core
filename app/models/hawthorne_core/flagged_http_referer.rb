class HawthorneCore::FlaggedHttpReferer < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'flagged_http_referers'
  self.primary_key = 'flagged_http_referer_id'

  def id = flagged_http_referer_id

  # -----------------------------------------------------------------------------

end
