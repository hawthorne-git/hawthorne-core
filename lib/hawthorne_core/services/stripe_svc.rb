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
    HawthorneCore::UserAction::Log.stripe_customer_created_failure(user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { email_address: email_address, exception_message: e.message })
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.create_customer', { user_id: user_id, email_address: email_address }, e)
    nil
  end

  # ----------------------------------------------------------------

  # update the customers email address
  def self.update_customer_email_address(customer_id, user_id, email_address)
    Stripe::Customer.update(customer_id, { email: email_address })
    HawthorneCore::UserAction::Log.stripe_customer_email_address_updated(user_id, { stripe_customer_id: customer_id, new_email_address: email_address })
  rescue Stripe::StripeError => e
    HawthorneCore::UserAction::Log.stripe_customer_email_address_updated_failure(user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { stripe_customer_id: customer_id, new_email_address: email_address, exception_message: e.message })
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.update_customer_email_address', {  stripe_customer_id: customer_id, user_id: user_id, new_email_address: email_address }, e)
  end

  # ----------------------------------------------------------------

  # create a setup intent (credit card) for a customer
  # this does NOT create the credit card - just setting up the form for the user to add a credit card
  def self.setup_intent_client_secret(customer_id, user_id)
    setup_intent = Stripe::SetupIntent.create(
      customer: customer_id,
      payment_method_types: ['card'],
      usage: 'off_session'
    )
    HawthorneCore::UserAction::Log.stripe_customer_setup_intent_created(user_id, { stripe_customer_id: customer_id, user_id: user_id, setup_intent_client_secret: setup_intent.client_secret })
    setup_intent.client_secret
  rescue Stripe::StripeError => e
    HawthorneCore::UserAction::Log.stripe_customer_setup_intent_created_failure(user_id, HawthorneCore::UserAction::FailureReason.exception_caught, { stripe_customer_id: customer_id, user_id: user_id, exception_message: e.message })
    HawthorneCore::CapturedException.log('HawthorneCore::Services::StripeSvc.setup_intent_client_secret', {  stripe_customer_id: customer_id, user_id: user_id }, e)
  end

  # ----------------------------------------------------------------

end