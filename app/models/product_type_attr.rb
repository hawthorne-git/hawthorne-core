class ProductTypeAttr < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_type_attrs'
  self.primary_key = 'product_type_attr_id'

  def id = product_type_attr_id

  # -----------------------------------------------------------------------------

end
