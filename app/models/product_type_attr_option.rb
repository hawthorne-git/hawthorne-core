class ProductTypeAttrOption < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_type_attr_options'
  self.primary_key = 'product_type_attr_option_id'

  def id = product_type_attr_option_id

  # -----------------------------------------------------------------------------

end
