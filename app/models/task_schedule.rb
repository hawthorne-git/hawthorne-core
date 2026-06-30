class TaskSchedule < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'task_schedules'
  self.primary_key = 'task_schedule_id'

  def id = task_schedule_id

  # -----------------------------------------------------------------------------

  # Mirrors the task_priority enum in the admin DB.
  PRIORITIES = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].freeze

  # Mirrors the task_effort enum in the admin DB.
  EFFORTS = ['LOW (<1 HR)', 'MEDIUM (1HR-3HR)', 'HIGH (3HR-8HR)', 'VERY HIGH (8HR-24HR)', 'EXTREME (>24HR)'].freeze

  # Mirrors the employee_group enum in the admin DB.
  ASSIGNABLE_GROUPS = ['CUT', 'DEVELOPER'].freeze

  # The units a schedule's frequency can be expressed in, mapped to the
  # ActiveSupport::Duration helper used to build the PostgreSQL interval. Building
  # the interval from a whitelisted unit (and a validated positive count) means the
  # frequency column only ever receives a valid value.
  FREQUENCY_UNITS = {
    'DAY' => :days,
    'WEEK' => :weeks,
    'MONTH' => :months,
    'YEAR' => :years
  }.freeze

  belongs_to :task_category, foreign_key: :task_category_id, optional: true
  belongs_to :assigned_employee, class_name: 'Employee', foreign_key: :assigned_employee_id, optional: true
  has_many :tasks, foreign_key: :task_schedule_id

  # -----------------------------------------------------------------------------

  # A schedule is assigned to either a specific employee or an employee group (never
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

  # The frequency (an ActiveSupport::Duration) split into a whole count and one of
  # FREQUENCY_UNITS, for the form. PostgreSQL normalizes weeks to days, so a "2 weeks"
  # frequency reads back as 14 days and is recovered here as 2 weeks.
  def frequency_count
    count, _unit = frequency_count_and_unit
    count
  end

  def frequency_unit
    _count, unit = frequency_count_and_unit
    unit
  end

  # The next run as a date, for the form's date field.
  def next_run_on
    next_run_at&.to_date
  end

  # Builds the frequency interval from a count and a unit (see FREQUENCY_UNITS).
  def set_frequency(count, unit)
    helper = FREQUENCY_UNITS[unit.to_s]
    self.frequency = helper ? count.to_i.public_send(helper) : nil
  end

  # -----------------------------------------------------------------------------

  # Called when the schedule is due. Creates the next OPEN task and advances to the next
  # run, unless a prior occurrence is still unresolved — in that case the existing open
  # task stands in for this cycle (no pile-up) and we just advance. Wrapped in a
  # transaction so the schedule only advances if the task is created.
  def run_due!
    transaction do
      create_occurrence!
      advance!
    end
  end

  # Records this run and moves next_run_at forward by whole frequency steps until it
  # is in the future. A schedule that fell behind several cycles is fast-forwarded to
  # the next future slot rather than backfilling a task for each missed cycle.
  def advance!
    now = Time.current
    next_at = next_run_at
    next_at += frequency while next_at <= now
    update!(last_run_at: now, next_run_at: next_at)
  end

  # -----------------------------------------------------------------------------

  private

  def create_occurrence!
    Task.create!(
      task_category_id: task_category_id,
      subject: subject,
      description: description,
      priority: priority,
      effort: effort || 'LOW (<1 HR)',
      assigned_employee_id: assigned_employee_id,
      assigned_employee_group: assigned_employee_group,
      status: 'OPEN',
      task_schedule_id: task_schedule_id
    )
  end

  def frequency_count_and_unit
    return [nil, nil] if frequency.blank?
    parts = frequency.parts
    if parts[:years].to_i.positive?
      [parts[:years], 'YEAR']
    elsif parts[:months].to_i.positive?
      [parts[:months], 'MONTH']
    elsif parts[:weeks].to_i.positive?
      [parts[:weeks], 'WEEK']
    elsif parts[:days].to_i.positive?
      days = parts[:days]
      (days % 7).zero? ? [days / 7, 'WEEK'] : [days, 'DAY']
    else
      [nil, nil]
    end
  end

  # -----------------------------------------------------------------------------

end
