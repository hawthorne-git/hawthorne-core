# v3.0

class HawthorneCore::UI::Form::CheckBoxComponent < ViewComponent::Base
  def initialize(form:, attribute:, label: nil, value:)
    @form = form
    @attribute = attribute
    @value = value
    @label = label
  end
end