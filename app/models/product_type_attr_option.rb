class ProductTypeAttrOption < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_type_attr_options'
  self.primary_key = 'product_type_attr_option_id'

  def id = product_type_attr_option_id

  # -----------------------------------------------------------------------------

  belongs_to :product_type_attr

  # products store the value (not the handle), so once a product has chosen it, it can't change, nor move to another
  # attribute
  validate :value_locked_once_used

  # -----------------------------------------------------------------------------

  # whether any product of this type has chosen this option (as its Select value, or within its MultiSelect list)
  def used? = persisted? && used_products.exists?

  def used_count = persisted? ? used_products.count : 0

  # the products that have chosen it, as saved (before any unsaved change of value or attribute)
  def used_products
    type_attr = ProductTypeAttr.find(product_type_attr_id_was || product_type_attr_id)
    key = type_attr.key
    stored = value_was || value
    Product.where(product_type_id: type_attr.product_type_id)
           .where('attrs @> ? OR attrs @> ?', { key => stored }.to_json, { key => [stored] }.to_json)
  end

  # -----------------------------------------------------------------------------

  private

  def value_locked_once_used
    return unless persisted? && (value_changed? || product_type_attr_id_changed?)
    return unless used?

    errors.add(:value, "can't be changed: products have chosen this option") if value_changed?
    errors.add(:product_type_attr, "can't be changed: products have chosen this option") if product_type_attr_id_changed?
  end

end
