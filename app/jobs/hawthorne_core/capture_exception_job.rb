# v3.0

# capture an exception
class HawthorneCore::CaptureExceptionJob < HawthorneCore::ApplicationJob

  queue_as :critical

  def perform(code_location, exception_class, exception_message, note)
    HawthorneCore::CapturedException.create!(
      code_location: code_location,
      exception_class: exception_class,
      exception_message: exception_message,
      note: note
    )
  end

end