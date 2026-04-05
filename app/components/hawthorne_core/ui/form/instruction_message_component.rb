# v3.0

class HawthorneCore::UI::Form::InstructionMessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end