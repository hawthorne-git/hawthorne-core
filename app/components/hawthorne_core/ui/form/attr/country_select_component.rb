# v3.0

class HawthorneCore::UI::Form::Attr::CountrySelectComponent < ViewComponent::Base
  def initialize(form:, countries:)
    @form = form
    @countries = countries
  end
end