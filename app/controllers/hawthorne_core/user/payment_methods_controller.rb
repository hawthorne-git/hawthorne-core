# v3.0

class HawthorneCore::User::PaymentMethodsController < HawthorneCore::AccountApplicationController

  include HawthorneCore::Validation::PaymentMethod,
          HawthorneCore::Validation::PaymentMethod::Stripe


  # -----------------------------------------------------------------------------

  # show the users payment methods
  def index

    # find the users credit cards
    @credit_cards = HawthorneCore::User.credit_cards(user_id:)

    @html_title = 'Credit Cards | Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to add a credit card
  def new

    # set up the user to add a credit card
    # the service key is a one-time identifier for the user to add a credit card
    # also determine if the user has an active payment method - if yes, they can set this new payment as default
    @service_key = HawthorneCore::User.create_payment_method_service_key(user_id:)
    @has_payment_method = HawthorneCore::UserPaymentMethod.has_payment_method?(user_id:)

    @html_title = 'Add Credit Card | Profile'

  end

  # -----------------------------------------------------------------------------

  # add a credit card
  def create

    payment_method_id = params[:payment_method_id]
    set_as_default = params[:set_as_default]

    # verify the payment method identifier is valid, and that the credit card (fingerprint) is not identical to another on file
    return redirect_on_invalid_payment_method_id(action: 'ADD_CREDIT_CARD_TO_ACCOUNT', payment_method_id:) unless payment_method_id_valid?(payment_method_id:)

    # add the credit card as a payment method
    HawthorneCore::UserPaymentMethod.perform_add(user_id:, action_location: 'ACCOUNT', payment_method_id:, set_as_default:)

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

  # delete a credit card
  def delete

    token = params[:token]

    # find the payment method to delete
    # verify that the payment method is found, and belongs to the user
    payment_method = HawthorneCore::UserPaymentMethod.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_payment_method_not_found(location: 'HawthorneCore::User::PaymentMethodsController.delete', token:) unless payment_method

    # delete the payment method, and detach the payment method from the service
    payment_method.perform_delete(detach_requested_by_user: true)

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

  # set a credit card as the default payment method
  def set_default

    token = params[:token]

    # find the payment method to set as default
    # verify that the payment method is found, and belongs to the user
    payment_method = HawthorneCore::UserPaymentMethod.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_payment_method_not_found(location: 'HawthorneCore::User::PaymentMethodsController.set_default', token:) unless payment_method

    # update the selected payment method as the default
    payment_method.set_as_default

    # redirect the user to view their payment methods
    redirect_to account_payment_methods_path

  end

  # -----------------------------------------------------------------------------

end