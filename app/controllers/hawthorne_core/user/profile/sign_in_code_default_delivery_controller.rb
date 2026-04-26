# v3.0

class HawthorneCore::User::Profile::SignInCodeDefaultDeliveryController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their sign-in code default delivery method
  def show

    # find the user - load required attributes
    @user = HawthorneCore::User.
      select(:sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Sign-In Code Delivery | Profile'

  end

  # -----------------------------------------------------------------------------

  # update the users sign-in code default delivery method
  def update

    sign_in_code_default_delivery = params[:sign_in_code_default_delivery]

    # ----------------------

    # find the user, then update their sign-in code default delivery method
    HawthorneCore::User.
      select(:user_id, :sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id]).
      update_sign_in_code_default_delivery(sign_in_code_default_delivery:)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end