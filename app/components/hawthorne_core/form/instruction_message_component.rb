class HawthorneCore::Form::InstructionMessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end