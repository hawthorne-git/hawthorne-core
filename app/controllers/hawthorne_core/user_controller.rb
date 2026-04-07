# v3.0

class HawthorneCore::UserController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?

  # ----------------------------------------------------------------------------- Show (Account)

  # show the users account
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email_address, :phone_number, :sign_in_pin_default_delivery).
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'My Account'

  end

  # -----------------------------------------------------------------------------

end