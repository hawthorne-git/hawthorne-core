class HawthorneCore::MessageComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end