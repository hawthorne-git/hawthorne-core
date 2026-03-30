# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?

  # -----------------------------------------------------------------------------

  # show the profile page
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email_address, :phone_number, :pin_default_delivery).
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Profile | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # update the users profile
  # just their full name and pin default delivery - email address / phone number are done solo
  def update

    # get the form attributes
    full_name = params[:full_name]
    pin_default_delivery = params[:pin_default_delivery].upcase

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :full_name).
      find_by(user_id: session[:user_id])

    # update the users profile attributes - log it
    user.update_columns(full_name: full_name, pin_default_delivery: pin_default_delivery)
    HawthorneCore::UserAction::Log.update_profile(user.id, { full_name: full_name, pin_default_delivery: pin_default_delivery }, request.remote_ip, cookies[:user_session_token])

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

end