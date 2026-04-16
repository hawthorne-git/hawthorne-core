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

    # ----------------------

    @html_title = 'Add Credit Card | My Profile'

  end

  # -----------------------------------------------------------------------------

  # receive the stripe payment method id from the frontend and save it
  def create

    stripe_payment_method_id = params[:stripe_payment_method_id]

    return head :unprocessable_entity if stripe_payment_method_id.blank?
    return head :unprocessable_entity unless stripe_payment_method_id.start_with?('pm_')

    # ----------------------

    # TODO: save stripe_payment_method_id to the database
    # e.g. current_user.payment_methods.create!(stripe_payment_method_id: stripe_payment_method_id)

    # ----------------------

    head :ok

  end

  # -----------------------------------------------------------------------------

end