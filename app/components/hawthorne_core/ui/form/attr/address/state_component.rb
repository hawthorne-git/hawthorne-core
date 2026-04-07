# v3.0

class HawthorneCore::UI::Form::Attr::Address::StateComponent < ViewComponent::Base
  def initialize(form:, attribute:, label:, value: nil, selected_country:, us_states:)
    @form = form
    @attribute = attribute
    @label = label
    @value = value
    @selected_country = selected_country
    @us_states = us_states
  end
end