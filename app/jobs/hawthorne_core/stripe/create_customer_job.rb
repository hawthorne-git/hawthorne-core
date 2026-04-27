# v3.0

# creates a customer, within the stripe payment service
class HawthorneCore::Stripe::CreateCustomerJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id)

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :email, :stripe_customer_id).
      active.
      find_by(user_id:)

    # exit in the unexpected case where the user already has a stripe customer account
    return if user.stripe_customer?

    # create the customer, within stripe
    # attach the stripe customer id to the user
    stripe_customer_id = HawthorneCore::Services::StripeSvc.create_customer(user.id, user.email)
    user.update_columns(stripe_customer_id: stripe_customer_id)

  end

  # ----------------------------------------------------------------

end