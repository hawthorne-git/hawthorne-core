# v3.0

class HawthorneCore::UI::Form::FormWrapperComponent < ViewComponent::Base
  include Turbo::FramesHelper
  def initialize(turbo_frame_errors_tag: nil, instruction_message: nil)
    @turbo_frame_errors_tag = turbo_frame_errors_tag
    @instruction_message = instruction_message
  end
end