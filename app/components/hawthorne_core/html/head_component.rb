class HawthorneCore::HTML::HeadComponent < ViewComponent::Base
  def initialize(application_name:, title:)
    @application_name = application_name
    @title = title
  end
end