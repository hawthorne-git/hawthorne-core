# v3.0

class HawthorneCore::SiteException < HawthorneCore::ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'site_exceptions'

  # -----------------------------------------------------------------------------

  def self.log(loc, note, e)
    HawthorneCore::LogExceptionJob.perform_later(loc, note, e&.class, e&.message)
  end

  # -----------------------------------------------------------------------------

end