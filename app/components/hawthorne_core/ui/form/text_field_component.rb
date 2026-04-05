# v3.0

class HawthorneCore::UI::Form::TextFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, label:, placeholder: nil, value: nil, disabled: false, required: false, autocomplete: :off, maxlength: 100, autofocus: false)
    @form = form
    @attribute = attribute
    @label = label
    @placeholder = placeholder
    @value = value
    @disabled = disabled
    @required = required
    @autocomplete = autocomplete
    @maxlength = maxlength
    @autofocus = autofocus
  end
end