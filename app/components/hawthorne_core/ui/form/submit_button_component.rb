# v3.0

class HawthorneCore::UI::Form::SubmitButtonComponent < ViewComponent::Base
  def initialize(form:, text:)
    @form = form
    @text = text
  end
end