class HawthorneCore::UserAction < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'user_actions'
  self.primary_key = 'user_action_id'

  def id = user_action_id

  # -----------------------------------------------------------------------------

end