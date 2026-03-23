# v3.0

class HawthorneCore::SiteUserAction < HawthorneCore::ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'site_user_actions'

  # -----------------------------------------------------------------------------

  def self.max_nbr_pin_authentication_attempts
    5
  end

  # -----------------------------------------------------------------------------

end