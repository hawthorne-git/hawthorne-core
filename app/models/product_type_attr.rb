class ProductTypeAttr < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # the tables a Reference attr may point at: table name => model class name. a product stores the id of a row in it
  # (ex: 'thread_colors' => 'ThreadColor'); add a table here before using it
  REFERENCE_TABLES = {
    'thread_colors' => 'ThreadColor',
    'thread_lines' => 'ThreadLine',
    'thread_line_packages' => 'ThreadLinePackage'
  }.freeze

  # -----------------------------------------------------------------------------

  self.table_name = 'product_type_attrs'
  self.primary_key = 'product_type_attr_id'

  def id = product_type_attr_id

  # -----------------------------------------------------------------------------

  belongs_to :product_type
  belongs_to :product_attr

  has_many :product_type_attr_options, -> { order(:order_nbr, :handle) }

  delegate :key, :data_type, :options?, :unit?, to: :product_attr

  # a Reference attr names a known table; any other attr names none
  validate :reference_table_allowed

  # what a product's stored value depends on, so once products of its type have a value for it, these can't change:
  # moving it to another type or attribute would leave their values behind, a Reference's table gives its stored ids
  # their meaning (ex: thread color 2615), and a unit gives a number its meaning (ex: inches)
  LOCKED_ONCE_USED = %w[product_type_id product_attr_id reference_table unit].freeze

  validate :locked_once_used

  # -----------------------------------------------------------------------------

  # the attr's name (ex: Width)
  def handle = product_attr.handle

  # the model a Reference attr's values are ids of (nil for any other attr)
  def reference_model = REFERENCE_TABLES[reference_table]&.constantize

  # the values a product may choose from (Select / MultiSelect), in order
  def option_values = product_type_attr_options.select(&:active?).map(&:value)

  # whether any product of its type has a value for it, and how many do (see LOCKED_ONCE_USED)
  def used? = persisted? && used_products.exists?

  def used_count = persisted? ? used_products.count : 0

  # the products of its type with a value for it, as saved (before any unsaved change of type or attribute)
  def used_products
    key = ProductAttr.where(product_attr_id: product_attr_id_was || product_attr_id).pick(:key)
    Product.where(product_type_id: product_type_id_was || product_type_id).where('attrs ? :key', key:)
  end

  # -----------------------------------------------------------------------------

  private

  def locked_once_used
    changed_locks = LOCKED_ONCE_USED.select { |attribute| attribute_changed?(attribute) }
    return if changed_locks.empty? || !used?

    changed_locks.each { |attribute| errors.add(attribute.delete_suffix('_id'), "can't be changed: products have a value for it") }
  end

  def reference_table_allowed
    if data_type == 'Reference'
      errors.add(:reference_table, "must be one of: #{REFERENCE_TABLES.keys.join(', ').presence || '(none set up yet)'}") unless REFERENCE_TABLES.key?(reference_table)
    elsif reference_table.present?
      errors.add(:reference_table, 'is only for Reference attributes')
    end
  end

end
