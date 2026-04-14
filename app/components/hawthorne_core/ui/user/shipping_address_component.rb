# v3.0

class HawthorneCore::UI::User::ShippingAddressComponent < ViewComponent::Base
  def initialize(shipping_address:)
    @shipping_address = shipping_address
  end
end