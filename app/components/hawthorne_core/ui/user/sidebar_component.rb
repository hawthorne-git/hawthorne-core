# v3.0

class HawthorneCore::UI::User::SidebarComponent < ViewComponent::Base
  def initialize(selected_sidebar_navigation_item:)
    @selected_sidebar_navigation_item = selected_sidebar_navigation_item
  end
end