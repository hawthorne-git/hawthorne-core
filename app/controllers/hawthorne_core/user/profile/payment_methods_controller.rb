# v3.0

class HawthorneCore::User::Profile::PaymentMethodsController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  def index

    # find the user
    @user = user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name, :stripe_customer_id).
      active.
      find_by(user_id: session[:user_id])

    # find the users active payment methods (in our database) ... just credit cards to start
    payment_methods = HawthorneCore::UserPaymentMethod.
      select(:user_payment_method_id, :token, :stripe_payment_method_id, :default).
      active.
      where(user_id: user.id)

    # find the users credit cards (in stripe)
    credit_cards = HawthorneCore::Services::StripeSvc.find_all_customer_credit_cards(user.stripe_customer_id, user.id)

    # ----------------------

    # find all active credit cards
    @active_credit_cards = []
    credit_cards.each do |credit_card|
      payment_method = payment_methods.find { |_payment_method| _payment_method.stripe_payment_method_id == credit_card[:stripe_payment_method_id] }
      next unless payment_method.present?
      next unless HawthorneCore::UserPaymentMethod.credit_card_active?(credit_card[:credit_card_expiration_month], credit_card[:credit_card_expiration_year])
      @active_credit_cards.push(credit_card.merge(token: payment_method.token, default: payment_method.default))
    end

    # ----------------------

    # if the user does not have any active credit cards in their profile,
    # redirect the user to add their first credit card
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

    # ----------------------

    # set up the user to add a credit card,
    # the setup intent - client secret is an identifier for the user to add a credit card to their stripe account
    @stripe_setup_intent_client_secret = HawthorneCore::Services::StripeSvc.setup_intent_client_secret(@user.stripe_customer_id, @user.id)

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
      redirect_to account_profile_new_payment_method_path and return if true
    end

    # ----------------------

    # determine if the user has a defaulted payment method
    has_default_payment_method = HawthorneCore::UserPaymentMethod.defaulted_payment_method_exists?(user.id)

    # create the user payment method
    HawthorneCore::UserPaymentMethod.create!(
      user_id: user.id,
      payment_method_type: 'CREDIT_CARD',
      stripe_payment_method_id: stripe_payment_method_id,
      default: !has_default_payment_method
    )

    # log it
    HawthorneCore::UserAction::Log.add_credit_card(user.id, { stripe_payment_method_id: stripe_payment_method_id }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their payment methods
    redirect_to account_profile_new_payment_method_path

  end

  # -----------------------------------------------------------------------------

  # remove a credit card
  def destroy

    # get the request attributes
    token = params[:token]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :stripe_customer_id).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # find the payment method to remove
    payment_method = HawthorneCore::UserPaymentMethod.
      select(:user_payment_method_id, :stripe_payment_method_id, :default).
      active.
      find_by(user_id: user.id, token: token)

    # in the unexpected case where the payment method is not found
    # log it, and redirect the user to view their payment methods
    unless payment_method
      HawthorneCore::UserAction::Log.remove_credit_card_failure(user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Payment method not found', token: token }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_profile_payment_methods_path and return
    end

    # ----------------------

    # detach the payment method from stripe
    HawthorneCore::Services::StripeSvc.detach_payment_method(payment_method.stripe_payment_method_id, user.id)

    # soft delete the record
    payment_method.soft_delete

    # if this was the default, assign default to the next active payment method
    if payment_method.default
      next_payment_method = HawthorneCore::UserPaymentMethod.active.where(user_id: user.id).first
      next_payment_method&.update!(default: true)
    end

    # log it
    HawthorneCore::UserAction::Log.remove_credit_card(user.id, { token: token }, request.remote_ip, cookies[:user_session_token])

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

    # clear the existing default and set the new one
    HawthorneCore::UserPaymentMethod.active.where(user_id: user.id).update_all(default: false)
    payment_method.update!(default: true)

    # ----------------------

    redirect_to account_profile_payment_methods_path

  end

  # -----------------------------------------------------------------------------

end