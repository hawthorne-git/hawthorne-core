class ProductTypeAttr < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # the tables a Reference attr may point at: table name => model class name. a product stores the id of a row in it
  # (ex: 'colors' => 'Color'); add a table here before using it
  REFERENCE_TABLES = {}.freeze

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

  # -----------------------------------------------------------------------------

  # the attr's name (ex: Width)
  def handle = product_attr.handle

  # the model a Reference attr's values are ids of (nil for any other attr)
  def reference_model = REFERENCE_TABLES[reference_table]&.constantize

  # the values a product may choose from (Select / MultiSelect), in order
  def option_values = product_type_attr_options.select(&:active?).map(&:value)

  # -----------------------------------------------------------------------------

  private

  def reference_table_allowed
    if data_type == 'Reference'
      errors.add(:reference_table, "must be one of: #{REFERENCE_TABLES.keys.join(', ').presence || '(none set up yet)'}") unless REFERENCE_TABLES.key?(reference_table)
    elsif reference_table.present?
      errors.add(:reference_table, 'is only for Reference attributes')
    end
  end

end
