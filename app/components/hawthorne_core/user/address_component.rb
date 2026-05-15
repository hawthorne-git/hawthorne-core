class HawthorneCore::User::AddressComponent < ViewComponent::Base
  def initialize(address:)
    @address = address
  end
end