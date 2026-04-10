# v3.0

class HawthorneCore::UI::User::SidebarNavigationComponent < ViewComponent::Base
  def initialize(navigation_component:)
    @navigation_component = navigation_component
  end
end