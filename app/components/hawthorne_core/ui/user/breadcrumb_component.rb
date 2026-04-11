# v3.0

class HawthorneCore::UI::User::BreadcrumbComponent < ViewComponent::Base
  def initialize(selected_sidebar_navigation_item:, title:)
    @selected_sidebar_navigation_item = selected_sidebar_navigation_item
    @title = title
  end
end