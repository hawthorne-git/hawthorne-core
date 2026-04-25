# v3.0

# log an exception
class HawthorneCore::CaptureExceptionJob < HawthorneCore::ApplicationJob

  queue_as :default

  def perform(**attrs) = HawthorneCore::CapturedException.create!(**attrs)

end