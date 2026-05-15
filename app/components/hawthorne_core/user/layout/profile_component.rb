class HawthorneCore::User::Layout::ProfileComponent < ViewComponent::Base
  def initialize(title:)
    @title = title
  end
end