# v3.0

class HawthorneCore::UI::User::ProfileAttrComponent < ViewComponent::Base
  def initialize(label:, description: nil, value:, url: nil)
    @label = label
    @description = description
    @value = value
    @url = url
  end
end