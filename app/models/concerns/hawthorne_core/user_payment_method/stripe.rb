# v3.0

module HawthorneCore::UserPaymentMethod::Stripe
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the stripe payment method id is valid
    def self.stripe_payment_method_id_valid?(stripe_payment_method_id:) = stripe_payment_method_id.to_s.start_with?('pm_')

    # -----------------------------------------------------------------------------

    # add a stripe credit card as a payment method
    def self.add_stripe_credit_card(user_id:, action_location:, stripe_payment_method_id:)
      HawthorneCore::UserPaymentMethod.create!(
        user_id:,
        payment_method_type: 'CREDIT_CARD',
        stripe_payment_method_id:,
        default: !HawthorneCore::User.find_by(user_id:).defaulted_payment_method_exists?
      )
      HawthorneCore::UserAction::Log.add_credit_card(user_id:, note: { service: 'STRIPE', action_location:, stripe_payment_method_id: })
    end

    # -----------------------------------------------------------------------------

  end

end