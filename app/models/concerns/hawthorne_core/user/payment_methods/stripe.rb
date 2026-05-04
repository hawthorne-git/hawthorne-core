# v3.0

module HawthorneCore::User::PaymentMethods::Stripe
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # find the users stripe customer id
    def self.stripe_customer_id(user_id:) = where(user_id:).pick(:stripe_customer_id)

    # -----------------------------------------------------------------------------

    # create the users stripe customer account (NOW), returning its stripe customer id
    def self.create_stripe_customer_now(user_id:)
      HawthorneCore::Stripe::CreateCustomerJob.perform_now(user_id:)
      HawthorneCore::User.stripe_customer_id(user_id:)
    end

    # -----------------------------------------------------------------------------

    # set up the user to add a credit card,
    # the setup intent client secret is a stripe identifier for the user to add a credit card to their stripe account
    def self.stripe_setup_intent_client_secret(user_id:)
      stripe_customer_id = HawthorneCore::User.stripe_customer_id(user_id:)
      stripe_customer_id = create_stripe_customer_now(user_id:) unless stripe_customer_id
      HawthorneCore::Services::StripeSvc.setup_intent_client_secret(user_id:, customer_id: stripe_customer_id)
    end

    # -----------------------------------------------------------------------------

  end

end