class HawthorneCore::Image < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  has_one_attached :file

  # -----------------------------------------------------------------------------

  self.table_name = 'images'
  self.primary_key = 'image_id'

  def id = image_id

  # -----------------------------------------------------------------------------

end
