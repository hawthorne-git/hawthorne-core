# v3.0

module HawthorneCore::User::PaymentMethods
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # find the active stripe credit cards for the user
    def active_stripe_credit_cards = HawthorneCore::UserPaymentMethod.active_stripe_credit_cards(id, stripe_customer_id)

    # determine if the user has a defaulted payment method
    def defaulted_payment_method_exists? = HawthorneCore::UserPaymentMethod.defaulted_payment_method_exists?(id)

    # determine if the user has exactly one active credit card
    def one_active_credit_card? = HawthorneCore::UserPaymentMethod.one_active_credit_card?(id)

    # set all the user payment methods to not be defaulted
    def set_all_payment_methods_to_not_defaulted = HawthorneCore::UserPaymentMethod.set_all_payment_methods_to_not_defaulted(id)

    # determine if the user has a stripe customer account
    def stripe_customer? = stripe_customer_id.present?

    # -----------------------------------------------------------------------------

  end

end