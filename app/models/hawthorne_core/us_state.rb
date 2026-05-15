class HawthorneCore::UsState < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'us_states'
  self.primary_key = 'us_state_id'

  def id = us_state_id

  # -----------------------------------------------------------------------------

  # find all states that we ship to
  def self.ship_to = active.where(ship_to: true).order(handle: :asc)

  # -----------------------------------------------------------------------------

end