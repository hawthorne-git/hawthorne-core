# v3.0

class HawthorneCore::UI::Form::FormWrapperComponent < ViewComponent::Base
  include Turbo::FramesHelper
  def initialize(instruction_message: nil)
    @instruction_message = instruction_message
  end
end