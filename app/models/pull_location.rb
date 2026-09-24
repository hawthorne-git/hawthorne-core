class PullLocation < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'pull_locations'
  self.primary_key = 'pull_location_id'

  def id = pull_location_id

  # -----------------------------------------------------------------------------

end
