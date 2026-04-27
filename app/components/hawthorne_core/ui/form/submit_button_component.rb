# v3.0

class HawthorneCore::UI::Form::SubmitButtonComponent < ViewComponent::Base
  def initialize(form:, submit_button_text:)
    @form = form
    @submit_button_text = submit_button_text
  end
end