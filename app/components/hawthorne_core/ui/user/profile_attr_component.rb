# v3.0

class HawthorneCore::UI::User::ProfileAttrComponent < ViewComponent::Base
  def initialize(label:, value:, url: nil)
    @label = label
    @value = value
    @url = url
  end
end