# v3.0

class HawthorneCore::User::Profile::PaymentMethodsController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  def index

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name, :stripe_customer_id).
      active.
      find_by(user_id: session[:user_id])

    # find the users active stripe credit cards
    @active_credit_cards = @user.active_stripe_credit_cards

    # redirect the user to add a card if they do not have any active credit cards
    redirect_to account_profile_new_payment_method_path and return unless @active_credit_cards.any?

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

    # set up the user to add a credit card,
    # the setup intent - client secret is a stripe identifier for the user to add a credit card to their stripe account
    @stripe_setup_intent_client_secret = HawthorneCore::Services::StripeSvc.setup_intent_client_secret(@user.id, @user.stripe_customer_id)

    # ----------------------

    @html_title = 'Add Credit Card | My Profile'

  end

  # -----------------------------------------------------------------------------

  # receive the stripe payment method id from the frontend and save it
  def create

    # get the request attributes
    stripe_payment_method_id = params[:stripe_payment_method_id]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # verify that the stripe payment method id is present and is starts with 'pm_'
    # if invalid - log it, return back and display all payment methods
    if stripe_payment_method_id.blank? || !stripe_payment_method_id.start_with?('pm_')
      HawthorneCore::UserAction::Log.add_credit_card_failure(user.id, HawthorneCore::UserAction::FailureReason.stripe_payment_method_id_invalid, { stripe_payment_method_id: stripe_payment_method_id }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_profile_new_payment_method_path and return
    end

    # ----------------------

    # create the user payment method
    # set as  default, if the user does not have an existing defaulted payment method
    HawthorneCore::UserPaymentMethod.create!(
      user_id: user.id,
      payment_method_type: 'CREDIT_CARD',
      stripe_payment_method_id: stripe_payment_method_id,
      default: !user.defaulted_payment_method_exists?
    )

    # log it
    HawthorneCore::UserAction::Log.add_credit_card(user.id, { stripe_payment_method_id: stripe_payment_method_id }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their payment methods
    redirect_to account_profile_new_payment_method_path

  end

  # -----------------------------------------------------------------------------

  # remove a credit card - soft delete in our database, and detach in stripe
  def delete

    # get the request attributes
    token = params[:token]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # find the payment method to soft delete / detach in stripe
    payment_method = HawthorneCore::UserPaymentMethod.
      select(:user_payment_method_id, :stripe_payment_method_id, :default).
      active.
      find_by(user_id: user.id, token: token)

    # in the unexpected case where the payment method is not found
    # redirect the user to view their payment methods
    redirect_to account_profile_payment_methods_path and return unless payment_method

    # ----------------------

    # detach the payment method from stripe
    HawthorneCore::Services::StripeSvc.detach_payment_method(user.id, payment_method.stripe_payment_method_id)

    # soft delete the record
    payment_method.soft_delete

    # log it
    HawthorneCore::UserAction::Log.remove_credit_card(user.id, { token: token }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # if this user has one active credit card - set this card as the default
    if user.one_active_credit_card?
      payment_method_to_default = HawthorneCore::UserPaymentMethod.active.where(user_id: user.id).first
      payment_method_to_default.update_columns(default: true)
    end

    # ----------------------

    redirect_to account_profile_payment_methods_path

  end

  # -----------------------------------------------------------------------------

  # set a credit card as the default
  def set_default

    # get the request attributes
    token = params[:token]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # find the payment method to set as default
    payment_method = HawthorneCore::UserPaymentMethod.
      select(:user_payment_method_id).
      active.
      find_by(user_id: user.id, token: token)

    # in the unexpected case where the payment method is not found
    # redirect the user to view their payment methods
    redirect_to account_profile_payment_methods_path and return unless payment_method

    # ----------------------

    # set all the user payment methods to not be defaulted
    user.set_all_payment_methods_to_not_defaulted

    # update the selected payment method as the default
    payment_method.update_columns(default: true)

    # ----------------------

    # redirect the user to view their payment methods
    redirect_to account_profile_payment_methods_path

  end

  # -----------------------------------------------------------------------------

end