class HawthorneCore::User::TitleComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end
end