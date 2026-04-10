# v3.0

class HawthorneCore::UI::User::SidebarComponent < ViewComponent::Base
  def initialize(user:, selected_sidebar_navigation:)
    @user = user
    @selected_sidebar_navigation = selected_sidebar_navigation
  end
end