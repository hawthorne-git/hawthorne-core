# v3.0

class HawthorneCore::Services::StripeSvc

  # ----------------------------------------------------------------

  # create a stripe customer, returning its stripe customer id
  def self.create_customer(user_id, email_address)
    customer = Stripe::Customer.create(
      email: email_address,
      metadata: {
        user_id: user_id
      }
    )
    HawthorneCore::UserAction::Log.stripe_customer_created(user_id, { email_address: email_address, stripe_customer_id: customer.id })
    customer.id
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.create_customer', { user_id: user_id, email_address: email_address }, e)
    nil
  end

  # ----------------------------------------------------------------

  # detach a payment method from a customer (removes the credit card)
  def self.detach_payment_method(user_id, stripe_payment_method_id)
    Stripe::PaymentMethod.detach(stripe_payment_method_id)
    HawthorneCore::UserAction::Log.stripe_credit_card_detached(user_id, { stripe_payment_method_id: stripe_payment_method_id })
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.detach_payment_method', { user_id: user_id, stripe_payment_method_id: stripe_payment_method_id }, e)
  end

  # ----------------------------------------------------------------

  # find all customer credit cards, in an array of hashes
  def self.find_all_customer_credit_cards(user_id, customer_id)
    payment_methods = Stripe::PaymentMethod.list(customer: customer_id, type: 'card')
    payment_methods.data.map do |payment_method|
      {
        stripe_payment_method_id: payment_method.id,
        stripe_fingerprint: payment_method.card.fingerprint,
        brand: payment_method.card.brand,
        credit_card_last4: payment_method.card.last4,
        credit_card_expiration_month: payment_method.card.exp_month,
        credit_card_expiration_year: payment_method.card.exp_year
      }
    end
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.find_all_customer_credit_cards', { user_id: user_id, customer_id: customer_id }, e)
    nil
  end

  # ----------------------------------------------------------------

  # update the customers email address
  def self.update_customer_email_address(user_id, new_email_address, customer_id)
    Stripe::Customer.update(customer_id, { email: new_email_address })
    HawthorneCore::UserAction::Log.stripe_customer_email_address_updated(user_id, { stripe_customer_id: customer_id, new_email_address: new_email_address })
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.update_customer_email_address', { stripe_customer_id: customer_id, user_id: user_id, new_email_address: new_email_address }, e)
  end

  # ----------------------------------------------------------------

  # create a setup intent (credit card) for a customer
  # this does NOT create the credit card - just setting up the form for the user to add a credit card
  def self.setup_intent_client_secret(user_id, customer_id)
    setup_intent = Stripe::SetupIntent.create(
      customer: customer_id,
      payment_method_types: ['card'],
      usage: 'off_session'
    )
    HawthorneCore::UserAction::Log.stripe_setup_intent_created(user_id, { stripe_customer_id: customer_id, user_id: user_id, setup_intent_client_secret: setup_intent.client_secret })
    setup_intent.client_secret
  rescue Stripe::StripeError => e
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.setup_intent_client_secret', { stripe_customer_id: customer_id, user_id: user_id }, e)
  end

  # ----------------------------------------------------------------

end