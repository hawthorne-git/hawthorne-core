class Image < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # exclude :touch so active storage attaching/analyzing the file (which touches
  # the record via the attachment's touch: true) doesn't log empty update versions
  has_paper_trail versions: { class_name: 'Version' }, on: %i[create update destroy]

  has_one_attached :file

  belongs_to :image_type, class_name: 'ImageType'

  validate :image_type_active_when_activating

  # a replaced file (see ImageHelper#attach_image_helper bumping file_version) is described again, even over a hand
  # edit, since the old visual description no longer matches it
  before_update :reset_visual_description, if: :file_version_changed?

  # a supplier main image is described for product search once its file is uploaded or replaced, or it becomes a
  # supplier main image (see Ai::ImageVisualDescriptionJob, which skips one that doesn't need it)
  after_commit -> { Ai::ImageVisualDescriptionJob.perform_later(image_id:) }, on: [:create, :update],
               if: -> { supplier_main_image? && (saved_change_to_file_key? || saved_change_to_file_version? || saved_change_to_image_type_id?) }

  # -----------------------------------------------------------------------------

  self.table_name = 'images'
  self.primary_key = 'image_id'

  def id = image_id

  # whether this is a product's supplier main image (see Product::SUPPLIER_MAIN_IMAGE_TYPE)
  def supplier_main_image? = image_type&.handle == Product::SUPPLIER_MAIN_IMAGE_TYPE

  # -----------------------------------------------------------------------------

  private

  def reset_visual_description
    self.visual_description = nil
    self.visual_attrs = nil
    self.visual_description_ai_model_prompt_id = nil
    self.update_visual_description_with_ai = true
  end

  # an inactive image cannot be set as active while its image type is inactive
  def image_type_active_when_activating
    return unless deleted_changed? && !deleted?
    if image_type&.deleted?
      errors.add(:base, "Cannot be set as active while its image type '#{image_type.handle}' is inactive")
    end
  end

end
