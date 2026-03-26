# v3.0

class HawthorneCore::CapturedException < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'captured_exceptions'

  def id = captured_exception_id

  # -----------------------------------------------------------------------------

  # log a captured exception ... in a job
  def self.log(code_location, note, e)
    HawthorneCore::CaptureExceptionJob.perform_later(code_location, e&.class, e&.message, note)
  end

  # -----------------------------------------------------------------------------

end