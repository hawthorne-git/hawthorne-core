class TaskCategory < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  validate :no_active_tasks_when_inactivating

  # -----------------------------------------------------------------------------

  self.table_name = 'task_categories'
  self.primary_key = 'task_category_id'

  def id = task_category_id

  # -----------------------------------------------------------------------------

  belongs_to :parent, class_name: 'TaskCategory', foreign_key: :parent_id, optional: true
  has_many :children, class_name: 'TaskCategory', foreign_key: :parent_id

  # -----------------------------------------------------------------------------

  private

  # a category cannot be set as inactive while it still has active tasks
  def no_active_tasks_when_inactivating
    return unless deleted? && deleted_changed?
    if Task.where(task_category_id: task_category_id, deleted: false).exists?
      errors.add(:base, 'Cannot be set as inactive while it has active tasks')
    end
  end

end
