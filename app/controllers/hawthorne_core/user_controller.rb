# v3.0

class HawthorneCore::UserController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to these actions
  # if the user is not signed in ... the user is redirected to the sign-in page
  before_action :verify_signed_in?, only: [
    :show
  ]

  # ----------------------------------------------------------------------------- Show (Account)

  # show the users account
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :phone_number, :full_name).
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'My Account'

  end

  # -----------------------------------------------------------------------------

end