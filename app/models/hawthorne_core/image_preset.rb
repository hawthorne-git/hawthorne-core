class HawthorneCore::ImagePreset < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  validate :no_active_image_types_when_inactivating

  # -----------------------------------------------------------------------------

  self.table_name = 'image_presets'
  self.primary_key = 'image_preset_id'

  def id = image_preset_id

  # -----------------------------------------------------------------------------

  private

  # a preset cannot be set as inactive while active image types still reference it
  def no_active_image_types_when_inactivating
    return unless deleted? && deleted_changed?
    if HawthorneCore::ImageType.where(image_preset_id: image_preset_id, deleted: false).exists?
      errors.add(:base, 'Cannot be set as inactive while it has active image types')
    end
  end

end
