# v3.0

class HawthorneCore::UI::Form::HiddenFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, required: false, value:)
    @form = form
    @attribute = attribute
    @required = required
    @value = value
  end
end