class PickLocation < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'pick_locations'
  self.primary_key = 'pick_location_id'

  def id = pick_location_id

  # -----------------------------------------------------------------------------

end
