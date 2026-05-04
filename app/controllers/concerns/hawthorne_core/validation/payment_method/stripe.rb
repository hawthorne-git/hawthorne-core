# v3.0

module HawthorneCore::Validation::PaymentMethod::Stripe
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # redirect when the stripe payment method id is invalid
    def redirect_on_invalid_stripe_payment_method_id(action:, stripe_payment_method_id:)
      redirect_to_path = account_payment_methods_path if action == 'ADD_CREDIT_CARD_TO_ACCOUNT'
      HawthorneCore::UserAction::Log.add_credit_card_failure(failure_reason: HawthorneCore::UserAction::FailureReason.stripe_payment_method_invalid, note: { service: 'STRIPE', action:, stripe_payment_method_id: })
      redirect_to redirect_to_path
    end

    # ---------------------------------------------------------------------------

  end

end