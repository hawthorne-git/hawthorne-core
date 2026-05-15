class HawthorneCore::UI::User::PaymentMethodComponent < ViewComponent::Base
  def initialize(payment_method:)
    @payment_method = payment_method
  end
end