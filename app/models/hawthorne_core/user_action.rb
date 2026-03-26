# v3.0

class HawthorneCore::UserAction < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'user_actions'

  def id = user_action_id

  def self.create_record(**attrs) = create!(attrs)

  # -----------------------------------------------------------------------------

end