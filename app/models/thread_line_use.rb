class ThreadLineUse < ActiveRecordBaseApp

  has_paper_trail versions: { class_name: 'Version' }

  # how well suited a line is to a use, as Mettler / ASPO rate their categories with dots (ex: ASPO 30 Sewing 3)
  RATINGS = (1..3)

  belongs_to :thread_line
  belongs_to :thread_use

  # a use is named once per line (the same as the unique index on thread_line_id, thread_use_id)
  validates :thread_use_id, uniqueness: { scope: :thread_line_id }
  validates :rating, inclusion: { in: RATINGS }, allow_nil: true

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_line_uses'
  self.primary_key = 'thread_line_use_id'

  def id = thread_line_use_id

  # -----------------------------------------------------------------------------

end
