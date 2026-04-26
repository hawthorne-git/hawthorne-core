# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the users profile page
  def show

    # find the user - load required attributes
    @user = HawthorneCore::User.
      select(:name, :email, :phone_number, :sign_in_code_default_delivery).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Profile'

  end

  # -----------------------------------------------------------------------------

end