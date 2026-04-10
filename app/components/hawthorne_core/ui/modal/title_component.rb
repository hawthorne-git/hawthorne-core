# v3.0

class HawthorneCore::UI::Modal::TitleComponent < ViewComponent::Base
  def initialize(text:, modal_element_id:)
    @text = text
    @modal_element_id = modal_element_id
  end
end