# v3.0

# log a user action
class HawthorneCore::User::LogActionJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(**attrs) = HawthorneCore::UserAction.create!(**attrs)

end