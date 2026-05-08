# v3.0

module HawthorneCore::UserPaymentMethod::Stripe
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if a stripe credit card is expired
    def self.stripe_credit_card_expired?(credit_card:)
      HawthorneCore::Helpers::CreditCard.credit_card_expired?(
        exp_month: credit_card[:credit_card_exp_month].to_i,
        exp_year: credit_card[:credit_card_exp_year].to_i
      )
    end

    # -----------------------------------------------------------------------------

    # order the stripe credit cards - with the defaulted credit card first, then last used at checkout, then created at
    def self.stripe_credit_cards_ordered(credit_cards:) = credit_cards.sort_by { |e| [e[:default] ? 0 : 1, -e[:last_checkout_selected_at].to_i, -e[:created_at].to_i] }

    # -----------------------------------------------------------------------------

    # add a stripe credit card as a payment method
    def self.add_stripe_credit_card(user_id:, action_location:, payment_method_id:)
      HawthorneCore::UserPaymentMethod.create!(
        user_id:,
        payment_method_type: 'CREDIT_CARD',
        stripe_payment_method_id: payment_method_id,
        default: !HawthorneCore::User.find_by(user_id:).default_exists?
      )
      HawthorneCore::UserAction::Log.add_payment_method(user_id:, note: { service: 'STRIPE', payment_method_type: 'CREDIT_CARD', action_location:, payment_method_id: })
    end

    # -----------------------------------------------------------------------------

    # find the users (active) stripe credit cards
    def self.stripe_credit_cards(user_id:, customer_id:)

      # find the users credit cards, in our database and in stripe
      credit_cards_in_db = active.where(user_id:, payment_method_type: 'CREDIT_CARD').where.not(stripe_payment_method_id: nil)
      credit_cards_in_stripe = HawthorneCore::Services::StripeSvc.find_all_customer_credit_cards(user_id:, customer_id:)

      # capture all credit cards
      # iterate through all credit cards in stripe ...
      # if the credit card is not found in our database - skip
      # if the credit card is expired - make sure it is not marked as defaulted, and skip
      # if the credit card is found in our database and current, add to the list of users credit cards
      credit_cards = []
      credit_cards_in_stripe.each do |credit_card_in_stripe|
        credit_card_in_db = credit_cards_in_db.find { |pm| pm.stripe_payment_method_id == credit_card_in_stripe[:payment_method_id] }
        next unless credit_card_in_db.present?
        if HawthorneCore::UserPaymentMethod.stripe_credit_card_expired?(credit_card: credit_card_in_stripe)
          credit_card_in_db.update_columns(default: false) if credit_card_in_db.default?
          credit_card_in_db.perform_delete
          next
        end
        credit_cards.push(credit_card_in_stripe.merge(token: credit_card_in_db.token, default: credit_card_in_db.default, last_checkout_selected_at: credit_card_in_db.last_checkout_selected_at, created_at: credit_card_in_db.created_at))
      end

      # clean up a users defaulted payment methods (in our database)
      # if there was a change, then update the current credit card list
      clean_defaulted_result = clean_defaulted(user_id:)
      if clean_defaulted_result[:change_made]
        credit_cards.each { |e| e[:default] = false }
        credit_cards.find { |e| e[:token] == clean_defaulted_result[:token] }&.merge!(default: true)
      end

      # return the stripe credit cards ordered - with the defaulted credit card first, then last used at checkout, then created at
      return stripe_credit_cards_ordered(credit_cards:)

    end

    # -----------------------------------------------------------------------------

  end

end