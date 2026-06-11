class HawthorneCore::Image < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  has_one_attached :file

  # image_types live in the admin database; this association loads via a separate
  # query on that connection rather than a cross-database join
  belongs_to :image_type, class_name: 'HawthorneCore::ImageType'

  # -----------------------------------------------------------------------------

  self.table_name = 'images'
  self.primary_key = 'image_id'

  def id = image_id

  # -----------------------------------------------------------------------------

end
