# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the profile page
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email_address, :phone_number, :sign_in_pin_default_delivery).
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'My Profile'

  end

  # -----------------------------------------------------------------------------

end