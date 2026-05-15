class HawthorneCore::Form::HiddenFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, required: false, value:)
    @form = form
    @attribute = attribute
    @required = required
    @value = value
  end
end