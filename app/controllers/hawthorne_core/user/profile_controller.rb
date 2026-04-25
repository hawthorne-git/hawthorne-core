# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the profile page
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email_address, :phone_number, :sign_in_pin_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to add / update their full name
  def full_name_show

    # find the users full name
    @full_name = HawthorneCore::User.active.where(user_id: session[:user_id]).pick(:full_name)

    # ----------------------

    @html_title = 'Full Name | Profile'

  end

  # ----------------------

  # add / update the users full name
  def full_name_update

    # get the request attributes
    full_name = params[:full_name]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # temporarily capture the old and new values, for logging
    old_full_name = user.full_name
    new_full_name = full_name

    # update the users full name
    user.update_columns(full_name: new_full_name)

    # log it
    HawthorneCore::UserAction::Log.update_profile(note: { old_full_name: old_full_name, new_full_name: new_full_name })

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to update how their sign-in pin is sent by default ... either via an email or text message
  def sign_in_pin_default_delivery_show

    # find the users sign-in pin default delivery
    @sign_in_pin_default_delivery = HawthorneCore::User.active.where(user_id: session[:user_id]).pick(:sign_in_pin_default_delivery)

    # ----------------------

    @html_title = 'Sign-In Code Delivery | Profile'

  end

  # ----------------------

  # update how the user is to receive their sign-in pin by default ... either via an email or text message
  def sign_in_pin_default_delivery_update

    # get the request attributes
    sign_in_pin_default_delivery = params[:sign_in_pin_default_delivery]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :sign_in_pin_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    sign_in_pin_default_delivery = 'sdsfd'

    # in the unexpected case where the selected pin delivery method is not an expected value - log it, return back to their profile
    redirect_to account_profile_path and return unless HawthorneCore::User::SIGN_IN_PIN_DELIVERY_METHODS.include?(sign_in_pin_default_delivery)

    # ----------------------

    # temporarily capture the old and new values, for logging
    old_sign_in_pin_default_delivery = user.sign_in_pin_default_delivery
    new_sign_in_pin_default_delivery = sign_in_pin_default_delivery

    # update the users sign-in pin default delivery
    user.update_columns(sign_in_pin_default_delivery: new_sign_in_pin_default_delivery)

    # log it
    HawthorneCore::UserAction::Log.update_profile(user.id, { old_sign_in_pin_default_delivery: old_sign_in_pin_default_delivery, new_sign_in_pin_default_delivery: new_sign_in_pin_default_delivery }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end