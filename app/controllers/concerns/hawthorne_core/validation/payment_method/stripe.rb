# v3.0

module HawthorneCore::Validation::PaymentMethod::Stripe
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the stripe payment method id is valid
    def stripe_payment_method_id_valid?(payment_method_id:) = payment_method_id.to_s.start_with?('pm_')

    # ---------------------------------------------------------------------------

    # redirect when the stripe payment method id is invalid
    def redirect_on_invalid_stripe_payment_method_id(action:, payment_method_id:)
      redirect_to_path = account_payment_methods_path if action == 'ADD_CREDIT_CARD_TO_ACCOUNT'
      HawthorneCore::UserAction::Log.add_payment_method_failure(failure_reason: HawthorneCore::UserAction::FailureReason.stripe_payment_method_invalid, note: { service: 'STRIPE', payment_method_type: 'CREDIT_CARD', action:, payment_method_id: })
      redirect_to redirect_to_path
    end

    # ---------------------------------------------------------------------------

  end

end