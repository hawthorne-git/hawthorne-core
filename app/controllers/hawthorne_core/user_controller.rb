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
      select(:user_id, :full_name, :email_address, :phone_number, :pin_default_delivery).
      find_by(user_id: session[:user_id])

    # ----------------------

    puts HawthorneCore::Services::SmartySvc.verify_us_address('72 hilltop rd', '', 'rhinebeck', 'ny', '12572').to_s

    # ----------------------

    @html_title = 'My Account'

  end

  # -----------------------------------------------------------------------------

end