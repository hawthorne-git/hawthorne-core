# v3.0

class HawthorneCore::UsState < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'us_states'

  def id = us_state_id

  # -----------------------------------------------------------------------------

end