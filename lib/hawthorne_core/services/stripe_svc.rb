# Stripe service ... for payment methods (credit cards)
class HawthorneCore::Services::StripeSvc

  # ----------------------------------------------------------------

  # create a stripe customer
  # returning its customer id
  def self.create_customer(user_id:, email:)
    customer = Stripe::Customer.create(
      email:,
      metadata: { user_id: }
    )
    HawthorneCore::UserAction::Log.stripe_customer_created(user_id:, note: { email:, customer_id: customer.id })
    customer.id
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.create_customer', note: { user_id:, email: }, e:)
    nil
  end

  # ----------------------------------------------------------------

  # find a credit card expiry and postal_code
  def self.credit_card_expiry_and_postal_code(payment_method_id:)
    payment_method = payment_method(payment_method_id:)
    {
      exp_month: payment_method.card.exp_month,
      exp_year: payment_method.card.exp_year,
      postal_code: payment_method.billing_details.address.postal_code
    }
  end
  
  # ----------------------

  # find a credit card fingerprint
  # the stripe fingerprint is a unique string that identifies a specific card number
  def self.credit_card_fingerprint(payment_method_id:) = payment_method(payment_method_id:).card.fingerprint

  # ----------------------------------------------------------------

  # find all customer credit cards,
  # returning in an array of hashes
  def self.customer_credit_cards(user_id:, customer_id:)
    payment_methods = Stripe::PaymentMethod.list(customer: customer_id, type: 'card')
    payment_methods.data.map do |payment_method|
      {
        payment_method_id: payment_method.id,
        fingerprint: payment_method.card.fingerprint,
        brand: payment_method.card.brand,
        last4: payment_method.card.last4,
        exp_month: payment_method.card.exp_month,
        exp_year: payment_method.card.exp_year,
        zip: payment_method.billing_details.address.postal_code
      }
    end
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.customer_credit_cards', note: { user_id:, customer_id: customer_id }, e:)
    nil
  end

  # ----------------------------------------------------------------

  # detach a payment method from a customer
  def self.detach_payment_method(user_id:, payment_method_id:)
    Stripe::PaymentMethod.detach(payment_method_id)
    HawthorneCore::UserAction::Log.stripe_credit_card_detached(user_id:, note: { payment_method_id: })
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.detach_payment_method', note: { user_id:, payment_method_id: }, e:)
  end

  # ----------------------------------------------------------------

  # find a payment method
  def self.payment_method(payment_method_id:)
    Stripe::PaymentMethod.retrieve(payment_method_id)
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.payment_method', note: { payment_method_id: }, e:)
    nil
  end

  # ----------------------------------------------------------------

  # create a setup intent (credit card) for a customer
  # this does NOT create the credit card - just setting up the (javascript) form for the user to add a credit card
  def self.setup_intent_client_secret(user_id:, customer_id:)
    setup_intent = Stripe::SetupIntent.create(
      customer: customer_id,
      payment_method_types: ['card'],
      usage: 'off_session'
    )
    HawthorneCore::UserAction::Log.stripe_setup_intent_created(user_id:, note:  { customer_id:, setup_intent_client_secret: setup_intent.client_secret })
    setup_intent.client_secret
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.setup_intent_client_secret', note: { customer_id:, user_id: }, e:)
  end

  # ----------------------------------------------------------------

  # update the payment methods credit card expiration month / year, and its postal code
  def self.update_credit_card_expiry_and_zip(user_id:, payment_method_id:, exp_month:, exp_year:, postal_code:)
    Stripe::PaymentMethod.update(payment_method_id, {
      card: {
        exp_month:,
        exp_year:
      },
      billing_details: {
        address: {
          postal_code:
        }
      }
    })
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.update_credit_card_expiry_and_zip', note: { user_id:, payment_method_id:, }, e:)
  end

  # ----------------------

  # update the customers email
  def self.update_customer_email(user_id:, email:, customer_id:)
    Stripe::Customer.update(customer_id, { email: })
    HawthorneCore::UserAction::Log.stripe_customer_email_updated(user_id:, note: { customer_id:, email: })
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log(location: 'HawthorneCore::Services::StripeSvc.update_customer_email', note: { customer_id:, user_id:, email: }, e:)
  end

  # ----------------------------------------------------------------

end