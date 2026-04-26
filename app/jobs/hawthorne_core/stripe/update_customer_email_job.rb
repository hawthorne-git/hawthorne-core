# v3.0

# updates a customers email, within the stripe payment service
class HawthorneCore::Stripe::UpdateCustomerEmailJob < HawthorneCore::ApplicationJob

  queue_as :default

  # ----------------------------------------------------------------

  def perform(user_id:)

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :email, :stripe_customer_id).
      active.
      find_by(user_id: user_id)

    # update the customers email, within stripe
    HawthorneCore::Services::StripeSvc.update_customer_email(user.id, user.email, user.stripe_customer_id)

  end

  # ----------------------------------------------------------------

end