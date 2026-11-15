class ThreadUse < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  normalizes :handle, with: ->(handle) { handle.strip }

  validates :handle, presence: true
  # a use's name is unique, not case sensitive (the same as the unique index on lower(handle))
  validates :handle, uniqueness: { case_sensitive: false }, if: -> { handle.present? }

  # the category a method belongs to (ex: Quilting for Hand Quilting); nil for a category, or a method without one (ex:
  # Fiber Art)
  belongs_to :parent_thread_use, class_name: 'ThreadUse', optional: true

  # a category's methods, in their order
  has_many :child_thread_uses, -> { order(:order_nbr, :handle) }, class_name: 'ThreadUse', foreign_key: :parent_thread_use_id

  # the lines recommended for it
  has_many :thread_line_uses

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_uses'
  self.primary_key = 'thread_use_id'

  def id = thread_use_id

  # -----------------------------------------------------------------------------

  # whether it's at the top of the list (a category, or a method without one), rather than under a category
  def top_level? = parent_thread_use_id.nil?

  # its category then its name (ex: "Quilting - Hand Quilting"), or its name alone at the top
  def display_name = parent_thread_use ? "#{parent_thread_use.handle} - #{handle}" : handle

  # -----------------------------------------------------------------------------

end
