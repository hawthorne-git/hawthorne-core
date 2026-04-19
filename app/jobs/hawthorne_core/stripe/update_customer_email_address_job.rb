# v3.0

# updates a customers email address, within the stripe payment service
class HawthorneCore::Stripe::UpdateCustomerEmailAddressJob < HawthorneCore::ApplicationJob

  queue_as :default

  # ----------------------------------------------------------------

  def perform(user_id)

    # find the user by their id
    user = HawthorneCore::User.
      select(:user_id, :email_address, :stripe_customer_id).
      active.
      find_by(user_id: user_id)

    # update the customers email address, within stripe
    HawthorneCore::Services::StripeSvc.update_customer_email_address(user.id, user.email_address, user.stripe_customer_id)

  end

  # ----------------------------------------------------------------

end