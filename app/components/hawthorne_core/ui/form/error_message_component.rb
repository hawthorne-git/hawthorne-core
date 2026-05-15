class HawthorneCore::UI::Form::ErrorMessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end