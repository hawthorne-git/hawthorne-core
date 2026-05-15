class HawthorneCore::Form::Attr::Address::CountrySelectComponent < ViewComponent::Base
  def initialize(form:, countries:, selected_country: nil)
    @form = form
    @countries = countries
    @selected_country = selected_country
  end
end