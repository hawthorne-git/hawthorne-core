class HawthorneCore::ImageType < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'image_types'
  self.primary_key = 'image_type_id'

  def id = image_type_id

  # -----------------------------------------------------------------------------

end
