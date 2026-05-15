class HawthorneCore::User::SidebarNavigationComponent < ViewComponent::Base
  def initialize(navigation_component:)
    @navigation_component = navigation_component
  end
end