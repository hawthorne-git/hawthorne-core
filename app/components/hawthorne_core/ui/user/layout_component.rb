# v3.0

class HawthorneCore::UI::User::LayoutComponent < ViewComponent::Base
  def initialize(selected_sidebar_navigation_item:, title:, breadcrumb: nil)
    @selected_sidebar_navigation_item = selected_sidebar_navigation_item
    @title = title
    @breadcrumb = breadcrumb
  end
end