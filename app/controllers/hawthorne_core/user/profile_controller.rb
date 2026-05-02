# v3.0

class HawthorneCore::User::ProfileController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the users profile page
  def show

    # find the user
    @user = HawthorneCore::User.find_by(user_id:)

    # ----------------------

    @html_title = 'Profile'

  end

  # -----------------------------------------------------------------------------

end