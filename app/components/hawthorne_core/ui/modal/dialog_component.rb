# v3.0

class HawthorneCore::UI::Modal::DialogComponent < ViewComponent::Base
  def initialize(title:, modal_element_id:)
    @title = title
    @modal_element_id = modal_element_id
  end
end