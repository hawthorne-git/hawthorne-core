# v3.0

class HawthorneCore::UI::User::LayoutComponent < ViewComponent::Base
  def initialize(user:, selected_sidebar_navigation_item:, title:, breadcrumb: nil)
    @user = user
    @selected_sidebar_navigation_item = selected_sidebar_navigation_item
    @title = title
    @breadcrumb = breadcrumb
  end
end