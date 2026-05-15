class HawthorneCore::CapturedException < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'captured_exceptions'
  self.primary_key = 'captured_exception_id'

  def id = captured_exception_id

  # -----------------------------------------------------------------------------

  # log a captured exception ... in a job
  def self.log(location:, note:, e:) = HawthorneCore::CaptureExceptionJob.perform_later(location:, note:, exception_class: e&.class, exception_message: e&.message)

  # -----------------------------------------------------------------------------

end