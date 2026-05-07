# v3.0

module HawthorneCore::UserPaymentMethod::Stripe
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the stripe payment method id is valid
    def self.stripe_payment_method_id_valid?(stripe_payment_method_id:) = stripe_payment_method_id.to_s.start_with?('pm_')

    # find all active stripe credit cards
    def self.active_stripe_credit_cards = active.where(user_id:, payment_method_type: 'CREDIT_CARD').where.not(stripe_payment_method_id: nil)

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

    # find the users stripe credit cards
    # in doing so, clean up
    def self.stripe_credit_cards(user_id:, stripe_customer_id:)

      # clean the users defaulted payment methods, if needed
      clean_defaulted(user_id:)

      # find the users active stripe credit card payment methods (in our database)

      payment_methods = active.
        where(user_id:, payment_method_type: 'CREDIT_CARD').
        where.not(stripe_payment_method_id: nil)

      # find the users credit cards
      credit_cards = HawthorneCore::Services::StripeSvc.find_all_customer_credit_cards(user_id:, customer_id: stripe_customer_id)

      # find all active credit cards
      # in the process, if an expired credit card is marked as default - remove it as default
      active_credit_cards = []
      credit_cards.each do |credit_card|
        payment_method = payment_methods.find { |pm| pm.stripe_payment_method_id == credit_card[:stripe_payment_method_id] }
        next unless payment_method.present?
        if HawthorneCore::UserPaymentMethod.credit_card_active?(credit_card[:credit_card_expiration_month], credit_card[:credit_card_expiration_year])
          active_credit_cards.push(credit_card.merge(token: payment_method.token, default: payment_method.default))
        else
          payment_method.update_columns(default: false) if payment_method.default?
        end
      end

      # return all active credit cards
      return active_credit_cards

    end

    # -----------------------------------------------------------------------------


    # -----------------------------------------------------------------------------

  end

end