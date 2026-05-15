class HawthorneCore::User::Profile::SignInCodeDefaultDeliveryController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their sign-in code default delivery method
  def show

    # find the user sign-in code default delivery method
    @sign_in_code_default_delivery = HawthorneCore::User.where(user_id:).pick(:sign_in_code_default_delivery)

    @html_title = 'Sign-In Code Delivery | Profile'

  end

  # -----------------------------------------------------------------------------

  # update the users sign-in code default delivery method
  def update

    sign_in_code_default_delivery = params[:sign_in_code_default_delivery]
    sign_in_code_default_delivery_via_text_message = (sign_in_code_default_delivery == HawthorneCore::User::CODE_VIA_PHONE)

    # find the user
    user = HawthorneCore::User.find_by(user_id:)

    # if the user selected to receive their sign-in code default delivery via text message, and they do not have a phone number on record
    # forward the user to add a phone number
    redirect_to account_profile_phone_number_path and return if (sign_in_code_default_delivery_via_text_message && !user.phone_number?)

    # update the users sign-in code default delivery method
    user.update_sign_in_code_default_delivery(sign_in_code_default_delivery:)

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end