# v3.0

class HawthorneCore::UI::User::Layout::PaymentMethodsComponent < ViewComponent::Base
  def initialize(user:, title:)
    @user = user
    @title = title
  end
end