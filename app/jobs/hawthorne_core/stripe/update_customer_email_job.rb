# v3.0

# updates a customers email, within the stripe payment service
class HawthorneCore::Stripe::UpdateCustomerEmailJob < HawthorneCore::ApplicationJob

  queue_as :default

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user attributes
    user_id, email, customer_id = HawthorneCore::User.
      where(user_id:).
      pick(:user_id, :email, :stripe_customer_id)

    # update the customers email, within stripe
    HawthorneCore::Services::StripeSvc.update_customer_email(user_id:, email:, customer_id:)

  end

  # ----------------------------------------------------------------

end