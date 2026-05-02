# v3.0

class HawthorneCore::UsState < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'us_states'

  def id = us_state_id

  # -----------------------------------------------------------------------------

  # find all states that we ship to
  def self.ship_to = active.where(ship_to: true).order(handle: :asc)

  # -----------------------------------------------------------------------------

end