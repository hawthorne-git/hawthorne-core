class Task < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  validate :task_category_active_when_activating

  # -----------------------------------------------------------------------------

  self.table_name = 'tasks'
  self.primary_key = 'task_id'

  def id = task_id

  # -----------------------------------------------------------------------------

  # Mirrors the task_status enum in the admin DB.
  STATUSES = ['OPEN', 'IN PROGRESS', 'RESOLVED'].freeze

  # Mirrors the task_priority enum in the admin DB.
  PRIORITIES = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].freeze

  # Mirrors the task_effort enum in the admin DB.
  EFFORTS = ['LOW (<1 HR)', 'MEDIUM (1HR-3HR)', 'HIGH (3HR-8HR)', 'VERY HIGH (8HR-24HR)', 'EXTREME (>24HR)'].freeze

  RELEASE_NUMBERS = ['3.0', '3.1', '3.2'].freeze

  # Mirrors the employee_group enum in the admin DB.
  ASSIGNABLE_GROUPS = ['CUT', 'DEVELOPER'].freeze

  belongs_to :task_category, foreign_key: :task_category_id, optional: true
  belongs_to :assigned_employee, class_name: 'Employee', foreign_key: :assigned_employee_id, optional: true
  belongs_to :task_schedule, foreign_key: :task_schedule_id, optional: true
  has_many :task_comments, foreign_key: :task_id
  has_many_attached :task_files

  # A task is recurring when it is backed by a schedule that generates it on a cadence.
  def repeating?
    task_schedule_id.present?
  end

  # -----------------------------------------------------------------------------

  # A task is assigned to either a specific employee or an employee group (never
  # both). The form binds a single "Assigned To" select to this virtual attribute,
  # which encodes the choice as "employee:<id>" or "group:<GROUP>".
  def assigned_to
    if assigned_employee_id.present?
      "employee:#{assigned_employee_id}"
    elsif assigned_employee_group.present?
      "group:#{assigned_employee_group}"
    end
  end

  def assigned_to=(value)
    case value.to_s
    when /\Aemployee:(\d+)\z/
      self.assigned_employee_id = $1
      self.assigned_employee_group = nil
    when /\Agroup:(.+)\z/
      group = $1
      self.assigned_employee_group = ASSIGNABLE_GROUPS.include?(group) ? group : nil
      self.assigned_employee_id = nil
    else
      self.assigned_employee_id = nil
      self.assigned_employee_group = nil
    end
  end

  # -----------------------------------------------------------------------------

  private

  # a deleted task cannot be set as active while its task category is inactive
  def task_category_active_when_activating
    return unless deleted_changed? && !deleted?
    if task_category&.deleted?
      errors.add(:base, "Cannot be set as active while its task category '#{task_category.handle}' is inactive")
    end
  end

end
