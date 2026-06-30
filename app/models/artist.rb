class Artist < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'artists'
  self.primary_key = 'artist_id'

  def id = artist_id

  # -----------------------------------------------------------------------------

  belongs_to :bio_image, class_name: 'HawthorneCore::Image', foreign_key: :bio_image_id, optional: true
  belongs_to :hero_image, class_name: 'HawthorneCore::Image', foreign_key: :hero_image_id, optional: true

  attr_accessor :bio_image_file, :hero_image_file

  # -----------------------------------------------------------------------------

end
