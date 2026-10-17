class ProductAttr < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # the product_attr_data_type enum; a product's value for each, in products.attrs:
  #   Text - a string; Boolean - true / false; Integer - a whole number; Decimal - a number
  #   Select - one option value; MultiSelect - a list of option values; Reference - the id of a row (see ProductTypeAttr::REFERENCE_TABLES)
  DATA_TYPES = %w[Text Boolean Integer Decimal Select MultiSelect Reference].freeze

  # the data types whose values come from the product type attr's options
  OPTION_DATA_TYPES = %w[Select MultiSelect].freeze

  # the data types a unit (ex: Inches) applies to
  UNIT_DATA_TYPES = %w[Integer Decimal].freeze

  # products.attrs is keyed by this, so it's a stable, lowercase identifier (ex: width, sewing_difficulty)
  KEY_PATTERN = /\A[a-z][a-z0-9_]*\z/

  # -----------------------------------------------------------------------------

  self.table_name = 'product_attrs'
  self.primary_key = 'product_attr_id'

  def id = product_attr_id

  # -----------------------------------------------------------------------------

  has_many :product_type_attrs

  validates :key, format: { with: KEY_PATTERN, message: 'must be lowercase letters, numbers, and underscores, starting with a letter' }
  validates :data_type, inclusion: { in: DATA_TYPES }

  # once any product has a value for it, its key and data type can't change (the stored values would no longer match)
  validate :key_and_data_type_locked_once_used

  # -----------------------------------------------------------------------------

  def options? = OPTION_DATA_TYPES.include?(data_type)

  def unit? = UNIT_DATA_TYPES.include?(data_type)

  # whether any product has a value for this attr
  def used? = Product.where('attrs ? :key', key: key_was || key).exists?

  # -----------------------------------------------------------------------------

  private

  def key_and_data_type_locked_once_used
    return unless persisted? && (key_changed? || data_type_changed?)
    return unless used?

    errors.add(:key, "can't be changed: products have a value for it") if key_changed?
    errors.add(:data_type, "can't be changed: products have a value for it") if data_type_changed?
  end

end
