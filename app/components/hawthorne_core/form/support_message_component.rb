class HawthorneCore::Form::SupportMessageComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end