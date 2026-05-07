# v3.0

module HawthorneCore::User::PaymentMethods
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has a defaulted payment method
    def defaulted_payment_method_exists? = HawthorneCore::UserPaymentMethod.defaulted_payment_method_exists?(id)

    # determine if the user has exactly one active credit card
    def one_active_credit_card? = HawthorneCore::UserPaymentMethod.one_active_credit_card?(id)

    def active_credit_card = HawthorneCore::UserPaymentMethod.active.where(user_id:).first

    # determine if the user has a stripe customer account
    def stripe_customer? = stripe_customer_id.present?

    # -----------------------------------------------------------------------------

    # set all the user payment methods as not defaulted
    def self.set_all_payment_methods_as_not_defaulted(user_id:) = HawthorneCore::UserPaymentMethod.set_all_payment_methods_as_not_defaulted(user_id:)

    # -----------------------------------------------------------------------------

  end

end