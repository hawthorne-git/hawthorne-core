# v3.0

class HawthorneCore::UI::User::LayoutComponent < ViewComponent::Base
  def initialize(title:, user:)
    @user = user
    @title = title
  end
end