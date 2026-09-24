class ProductType < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_types'
  self.primary_key = 'product_type_id'

  def id = product_type_id

  # -----------------------------------------------------------------------------

end
