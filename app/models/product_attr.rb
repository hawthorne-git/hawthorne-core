class ProductAttr < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_attrs'
  self.primary_key = 'product_attr_id'

  def id = product_attr_id

  # -----------------------------------------------------------------------------

end
