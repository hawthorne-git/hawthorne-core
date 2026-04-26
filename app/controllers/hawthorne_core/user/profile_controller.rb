# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the profile page
  def show

    # find the user - used to welcome the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email, :phone_number, :sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to add / update their full name
  def full_name_show

    # find the user - used to welcome the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Full Name | Profile'

  end

  # ----------------------

  # add / update the users full name
  def full_name_update

    # get the request attributes
    full_name = params[:full_name]

    # ----------------------

    # find the user - add / update their full name
    HawthorneCore::User.
      select(:user_id, :full_name).
      active.
      find_by(user_id: session[:user_id]).
      update_full_name(full_name: full_name)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to update how their sign-in code is sent by default ... either via an email or text message
  def sign_in_code_default_delivery_show

    # find the user - used to welcome the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name, :sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Sign-In Code Delivery | Profile'

  end

  # ----------------------

  # update how the user is to receive their sign-in code by default ... either via an email or text message
  def sign_in_code_default_delivery_update

    # get the request attributes
    sign_in_code_default_delivery = params[:sign_in_code_default_delivery]

    # in the unexpected case where the selected code delivery method is not an expected value - redirect the user to view their profile
    redirect_to account_profile_path and return unless HawthorneCore::User::SIGN_IN_CODE_DELIVERY_METHODS.include?(sign_in_code_default_delivery)

    # ----------------------

    # find the user
    HawthorneCore::User.
      select(:user_id, :sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id]).
      update_sign_in_code_default_delivery?(sign_in_code_default_delivery: sign_in_code_default_delivery)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end