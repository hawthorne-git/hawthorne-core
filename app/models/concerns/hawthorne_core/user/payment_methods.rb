module HawthorneCore::User::PaymentMethods
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has a defaulted payment method
    def default_exists? = HawthorneCore::UserPaymentMethod.default_exists?(id)
    
    # -----------------------------------------------------------------------------

    # create the users payment methods service key - with stripe
    def self.create_payment_method_service_key(...) = HawthorneCore::User.stripe_service_key(...)

    # find the users credit cards - with stripe
    def self.credit_cards(...) = stripe_credit_cards(...)

    # -----------------------------------------------------------------------------

  end

end