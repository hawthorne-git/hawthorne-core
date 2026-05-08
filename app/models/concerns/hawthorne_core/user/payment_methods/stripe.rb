# v3.0

module HawthorneCore::User::PaymentMethods::Stripe
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has a stripe customer account
    def stripe_customer? = stripe_customer_id.present?

    # -----------------------------------------------------------------------------

    # find the users stripe customer id
    # in the unexpected case where the stripe customer account does not exist - create it, then return the users stripe customer id
    def self.stripe_customer_id(user_id:)
      customer_id = where(user_id:).pick(:stripe_customer_id)
      return customer_id if customer_id.present?
      HawthorneCore::Stripe::CreateCustomerJob.perform_now(user_id:)
      where(user_id:).pick(:stripe_customer_id)
    end

    # -----------------------------------------------------------------------------

    # set up the user to add a credit card,
    # the setup intent client secret is a stripe identifier embedded into the JavaScript
    def self.stripe_service_key(user_id:)
      customer_id = HawthorneCore::User.stripe_customer_id(user_id:)
      HawthorneCore::Services::StripeSvc.setup_intent_client_secret(user_id:, customer_id:)
    end

    # -----------------------------------------------------------------------------

    # find the users stripe credit cards
    def self.stripe_credit_cards(user_id:) = HawthorneCore::UserPaymentMethod.stripe_credit_cards(user_id:, customer_id: stripe_customer_id(user_id:))

    # -----------------------------------------------------------------------------

  end

end