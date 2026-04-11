# v3.0

class HawthorneCore::HTML::HeadComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end