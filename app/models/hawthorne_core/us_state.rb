# v3.0

class HawthorneCore::UsState < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'us_states'

  def id = us_state_id

  # -----------------------------------------------------------------------------

  def self.ship_to = select(:handle, :code_alpha2).active.where(ship_to: true).order(handle: :asc)

  # -----------------------------------------------------------------------------

end