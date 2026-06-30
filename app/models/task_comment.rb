class TaskComment < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'task_comments'
  self.primary_key = 'task_comment_id'

  def id = task_comment_id

  # -----------------------------------------------------------------------------

  belongs_to :task, foreign_key: :task_id
  belongs_to :employee, foreign_key: :employee_id

  # -----------------------------------------------------------------------------

end
