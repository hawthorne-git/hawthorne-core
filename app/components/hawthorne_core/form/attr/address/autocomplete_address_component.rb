class HawthorneCore::Form::Attr::Address::AutocompleteAddressComponent < ViewComponent::Base
  def initialize(form:, model:, selected_country:)
    @form = form
    @model = model
    @selected_country = selected_country
  end
end