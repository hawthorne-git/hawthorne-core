# v3.0

class HawthorneCore::User::Profile::PaymentMethodsController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  def index

    # ----------------------

    # if the user does not have any credit cards in their profile,
    # redirect the user to add their first credit card
    redirect_to account_profile_new_payment_method_path and return if true

    # ----------------------

    @html_title = 'Payment Methods | My Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page to add a credit card
  def new

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name, :stripe_customer_id).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @stripe_setup_intent_client_secret = HawthorneCore::Services::StripeSvc.setup_intent_client_secret(@user.stripe_customer_id, @user.id)
    @stripe_publishable_key = HawthorneCore::AppConfig.stripe_publishable_key

    # ----------------------

    @html_title = 'Add Credit Card | My Profile'

  end

  # -----------------------------------------------------------------------------

end