# v3.0

class HawthorneCore::UI::User::ProfileAttrComponent < ViewComponent::Base
  def initialize(label:, value:, url: nil, modal_element_id: nil)
    @label = label
    @value = value
    @url = url
    @modal_element_id = modal_element_id
  end
end