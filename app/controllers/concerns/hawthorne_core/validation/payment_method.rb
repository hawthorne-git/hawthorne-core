# v3.0

module HawthorneCore::Validation::PaymentMethod
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # redirect to view all payment methods when the payment method is not found
    def redirect_when_payment_method_not_found(location:, token:)
      HawthorneCore::UserAction::Log.payment_method_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { location:, message: 'Payment method not found', token: })
      redirect_to account_payment_methods_path
    end

    # ---------------------------------------------------------------------------

  end

end