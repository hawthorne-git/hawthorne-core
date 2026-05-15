class HawthorneCore::Form::LabelComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end