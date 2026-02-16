module HawthorneCore::FabricCollection::PreviewImage
  extend ActiveSupport::Concern

  included do

    has_one_attached :preview_image_2025

    # -----------------------------------------------------------------------------

    #  get the preview image - the image shown when viewing a list of fabric collections
    def preview_image
      preview_image_2025
    end

    # determine if a preview image exists
    def preview_image?
      !preview_image.attachment.nil?
    end

    # -----------------------------------------------------------------------------

  end

end