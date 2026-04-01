# v3.0

class HawthorneCore::UI::Form::SelectFieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, label:, options:, prompt:, html_options:)
    @form = form
    @attribute = attribute
    @label = label
    @options = options
    @prompt = prompt
    @html_options = html_options
  end
end