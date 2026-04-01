# v3.0

class HawthorneCore::UI::Form::TextFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, label:, placeholder: nil, value: nil, required: false, autocomplete: false, maxlength: 100)
    @form = form
    @attribute = attribute
    @label = label
    @placeholder = placeholder
    @value = value
    @required = required
    @autocomplete = autocomplete
    @maxlength = maxlength
  end
end