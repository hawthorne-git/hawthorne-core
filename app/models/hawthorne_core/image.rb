class HawthorneCore::Image < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'images'
  self.primary_key = 'image_id'

  def id = image_id

  # -----------------------------------------------------------------------------

end
