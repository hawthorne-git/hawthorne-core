class HawthorneCore::Image < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  has_one_attached :file

  # image_types live in the admin database; this association loads via a separate
  # query on that connection rather than a cross-database join
  belongs_to :image_type, class_name: 'HawthorneCore::ImageType'

  validate :image_type_active_when_activating

  # -----------------------------------------------------------------------------

  self.table_name = 'images'
  self.primary_key = 'image_id'

  def id = image_id

  # -----------------------------------------------------------------------------

  private

  # an inactive image cannot be set as active while its image type is inactive
  # (image_types live in the admin database, so this is a cross-connection query)
  def image_type_active_when_activating
    return unless deleted_changed? && !deleted?
    if image_type&.deleted?
      errors.add(:base, "Cannot be set as active while its image type '#{image_type.handle}' is inactive")
    end
  end

end
