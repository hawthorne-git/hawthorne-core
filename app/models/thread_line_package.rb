class ThreadLinePackage < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # a blank item number is saved as null
  normalizes :handle, with: ->(handle) { handle.strip }
  normalizes :item_nbr, with: ->(item_nbr) { item_nbr.strip.presence }

  validates :handle, presence: true
  # a package's name is unique within its line, not case sensitive (the same as the unique index on lower(handle))
  validates :handle, uniqueness: { scope: :thread_line_id, case_sensitive: false }, if: -> { handle.present? }
  validates :length_m, :length_yd, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  belongs_to :thread_line
  # the profile with its cost, dimensions and shipping, shared across lines (ex: Aurifil Large Spool)
  belongs_to :supplier_product_profile, optional: true

  delegate :supplier, to: :thread_line

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_line_packages'
  self.primary_key = 'thread_line_package_id'

  def id = thread_line_package_id

  # how much thread it holds (ex: "1000M / 1094Y"), or nil when neither length is known
  def length_label
    [("#{length_m}M" if length_m), ("#{length_yd}Y" if length_yd)].compact.join(' / ').presence
  end

  # the line and package together (ex: "40wt Large Spool")
  def display_name = "#{thread_line.handle} #{handle}"

  # -----------------------------------------------------------------------------

end
