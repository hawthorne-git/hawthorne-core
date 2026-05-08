# v3.0

module HawthorneCore::User::PaymentMethods
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has a defaulted payment method
    def default_exists? = HawthorneCore::UserPaymentMethod.default_exists?(id)

    # determine if the user has exactly one active credit card
    def one_credit_card? = HawthorneCore::UserPaymentMethod.one_credit_card?(id)

    # -----------------------------------------------------------------------------

    # find the users credit cards - with stripe
    def self.credit_cards(...) = stripe_credit_cards(...)

    # find the users payment methods service key - with stripe
    def self.payment_method_service_key(...) = HawthorneCore::User.stripe_service_key(...)

    # -----------------------------------------------------------------------------

  end

end