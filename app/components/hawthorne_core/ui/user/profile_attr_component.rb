# v3.0

class HawthorneCore::UI::User::ProfileAttrComponent < ViewComponent::Base
  def initialize(label:, value:)
    @label = label
    @value = value
  end
end