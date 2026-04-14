# v3.0

class HawthorneCore::UI::Form::Attr::Address::CountrySelectComponent < ViewComponent::Base
  def initialize(form:, countries:, selected_country: nil)
    @form = form
    @countries = countries
    @selected_country = selected_country
  end
end