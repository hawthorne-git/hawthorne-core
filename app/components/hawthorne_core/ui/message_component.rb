# v3.0

class HawthorneCore::UI::MessageComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end