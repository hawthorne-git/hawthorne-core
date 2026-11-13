class ThreadLine < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  normalizes :handle, with: ->(handle) { handle.strip }

  validates :handle, presence: true
  # a line's name is unique within its brand, not case sensitive (the same as the unique index on lower(handle))
  validates :handle, uniqueness: { scope: :supplier_id, case_sensitive: false }, if: -> { handle.present? }

  belongs_to :supplier

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_lines'
  self.primary_key = 'thread_line_id'

  def id = thread_line_id

  # -----------------------------------------------------------------------------

end
