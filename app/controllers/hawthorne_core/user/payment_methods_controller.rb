# v3.0

class HawthorneCore::User::PaymentMethodsController < HawthorneCore::AccountApplicationController

  include HawthorneCore::Validation::PaymentMethod,
          HawthorneCore::Validation::PaymentMethod::Stripe


  # -----------------------------------------------------------------------------

  # show the user payment methods
  def index

    # find the users credit cards
    @credit_cards = HawthorneCore::User.stripe_credit_cards(user_id:)

    # ----------------------

    @html_title = 'Credit Cards | Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page to add a credit card
  def new

    # set up the user to add a credit card,
    # the setup intent client secret is a stripe identifier for the user to add a credit card to their stripe account
    @stripe_setup_intent_client_secret = HawthorneCore::User.stripe_setup_intent_client_secret(user_id:)

    # ----------------------

    @html_title = 'Add Credit Card | Profile'

  end

  # -----------------------------------------------------------------------------

  # add a credit card
  def create

    stripe_payment_method_id = params[:stripe_payment_method_id]

    # verify the stripe payment method identifier is valid
    return redirect_on_invalid_stripe_payment_method_id(action: 'ADD_CREDIT_CARD_TO_ACCOUNT', stripe_payment_method_id:) unless HawthorneCore::UserPaymentMethod.stripe_payment_method_id_valid?(stripe_payment_method_id:)

    # add the stripe credit card as a payment method
    HawthorneCore::UserPaymentMethod.add_stripe_credit_card(user_id:, action_location: 'ACCOUNT', stripe_payment_method_id:)

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

  # delete a credit card
  def delete

    token = params[:token]

    # find the payment method to delete
    # verify the payment method is found, and belongs to the user
    payment_method = HawthorneCore::UserPaymentMethod.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_payment_method_not_found(location: 'HawthorneCore::User::PaymentMethodsController.delete', token:) unless payment_method

    # delete the payment method
    payment_method.perform_delete

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

  # set a credit card as the default payment method
  def set_default

    token = params[:token]

    # find the payment method to set as default
    # verify the payment method is found, and belongs to the user
    payment_method = HawthorneCore::UserPaymentMethod.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_payment_method_not_found(location: 'HawthorneCore::User::PaymentMethodsController.set_default', token:) unless payment_method

    # set all the user payment methods as not defaulted
    HawthorneCore::User.set_all_payment_methods_as_not_defaulted(user_id:)

    # update the selected payment method as the default
    payment_method.update_columns(default: true)

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

end