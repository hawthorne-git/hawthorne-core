# v3.0

class HawthorneCore::UI::Form::CheckBoxComponent < ViewComponent::Base
  def initialize(form:, attribute:, text_after_checkbox: nil)
    @form = form
    @attribute = attribute
    @text_after_checkbox = text_after_checkbox
  end
end