# v3.0

# creates a customer within the stripe payment service
class HawthorneCore::Stripe::CreateCustomerJob < HawthorneCore::ApplicationJob

  queue_as :critical

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user by their id
    # exit if the user already has an attached stripe customer account
    user = HawthorneCore::User.find_by(user_id:)
    return if user.stripe_customer?

    # creates a customer within the stripe payment service
    # attach the stripe customer id to the user
    stripe_customer_id = HawthorneCore::Services::StripeSvc.create_customer(user_id:, email: user.email)
    user.update_columns(stripe_customer_id:)

  end

  # ----------------------------------------------------------------

end