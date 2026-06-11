class HawthorneCore::ImagePreset < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'image_presets'
  self.primary_key = 'image_preset_id'

  def id = image_preset_id

  # -----------------------------------------------------------------------------

end
