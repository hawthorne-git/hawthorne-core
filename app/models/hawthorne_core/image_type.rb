class HawthorneCore::ImageType < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  belongs_to :image_preset, class_name: 'HawthorneCore::ImagePreset'

  validate :no_active_images_when_inactivating
  validate :image_preset_active_when_activating
  validate :slug_cannot_change_with_attached_images

  # -----------------------------------------------------------------------------

  self.table_name = 'image_types'
  self.primary_key = 'image_type_id'

  def id = image_type_id

  # -----------------------------------------------------------------------------

  private

  # an image type cannot be set as inactive while active images still reference it
  # (images live in the app database, so this is a separate cross-connection query)
  def no_active_images_when_inactivating
    return unless deleted? && deleted_changed?
    if HawthorneCore::Image.where(image_type_id: image_type_id, deleted: false).exists?
      errors.add(:base, 'Cannot be set as inactive while it has active images')
    end
  end

  # an inactive image type cannot be set as active while its image preset is inactive
  def image_preset_active_when_activating
    return unless deleted_changed? && !deleted?
    if image_preset&.deleted?
      errors.add(:base, "Cannot be set as active while its image preset '#{image_preset.handle}' is inactive")
    end
  end

  # the slug cannot be changed once any image (active or inactive) is attached to
  # this image type (images live in the app database)
  def slug_cannot_change_with_attached_images
    return unless persisted? && slug_changed?
    if HawthorneCore::Image.where(image_type_id: image_type_id).exists?
      errors.add(:slug, 'cannot be edited once the image type has attached images')
    end
  end

end
