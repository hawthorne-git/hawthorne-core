class ProductImage < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_images'
  self.primary_key = 'product_image_id'

  def id = product_image_id

  # -----------------------------------------------------------------------------

  belongs_to :product
  belongs_to :image

  # the image type sets the product image's role (see Product::MAIN_IMAGE_TYPE)
  delegate :image_type, to: :image

  # -----------------------------------------------------------------------------

end
