class ThreadLine < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  normalizes :handle, with: ->(handle) { handle.strip }

  validates :handle, presence: true
  # a line's name is unique within its brand, not case sensitive (the same as the unique index on lower(handle))
  validates :handle, uniqueness: { scope: :supplier_id, case_sensitive: false }, if: -> { handle.present? }

  belongs_to :supplier

  # the line the brand recommends in the bobbin with this one (ex: Aurifil 50wt for 80wt); may be itself or another
  # brand's line
  belongs_to :bobbin_thread_line, class_name: 'ThreadLine', optional: true

  # the package sizes it comes in (ex: Small Spool, Large Spool, Cone)
  has_many :thread_line_packages, -> { order(:order_nbr, :handle) }

  # what it's good for (ex: Quilting, rated 3; Hand Quilting), as its brand recommends it
  has_many :thread_line_uses
  has_many :thread_uses, through: :thread_line_uses

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_lines'
  self.primary_key = 'thread_line_id'

  def id = thread_line_id

  # -----------------------------------------------------------------------------

end
