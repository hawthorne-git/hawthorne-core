# v3.0

class HawthorneCore::UI::Form::SupportMessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end