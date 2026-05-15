module HawthorneCore::Validation::PaymentMethod
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # determine if the payment method id is valid - with stripe
    def payment_method_id_valid?(...) = stripe_payment_method_id_valid?(...)

    # redirect when the payment method id is invalid - with stripe
    def redirect_on_invalid_payment_method_id(...) = redirect_on_invalid_stripe_payment_method_id(...)

    # ---------------------------------------------------------------------------

    # redirect to view all payment methods when the payment method is not found
    def redirect_when_payment_method_not_found(location:, token:)
      HawthorneCore::UserAction::Log.payment_method_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { location:, message: 'Payment method not found', token: })
      redirect_to account_payment_methods_path
    end

    # ---------------------------------------------------------------------------

  end

end