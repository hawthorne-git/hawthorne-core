class ProductTypeAttrOption < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_type_attr_options'
  self.primary_key = 'product_type_attr_option_id'

  def id = product_type_attr_option_id

  # -----------------------------------------------------------------------------

  belongs_to :product_type_attr

  # products store the value (not the handle), so once a product has chosen it, it can't change
  validate :value_locked_once_used

  # -----------------------------------------------------------------------------

  # whether any product of this type has chosen this option (as its Select value, or within its MultiSelect list)
  def used?
    key = product_type_attr.key
    stored = value_was || value
    Product.where(product_type_id: product_type_attr.product_type_id)
           .where('attrs @> ? OR attrs @> ?', { key => stored }.to_json, { key => [stored] }.to_json)
           .exists?
  end

  # -----------------------------------------------------------------------------

  private

  def value_locked_once_used
    return unless persisted? && value_changed?

    errors.add(:value, "can't be changed: products have chosen this option") if used?
  end

end
