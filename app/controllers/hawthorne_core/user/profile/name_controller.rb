# v3.0

class HawthorneCore::User::Profile::NameController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their name
  def show

    # find the users name
    @name = HawthorneCore::User.
      where(user_id: session[:user_id]).
      pick(:name)

    # ----------------------

    @html_title = 'Name | Profile'

  end

  # -----------------------------------------------------------------------------

  # add / update the users name
  def update

    name = params[:name]

    # ----------------------

    # find the user, then update their name
    HawthorneCore::User.
      select(:user_id, :name).
      find_by(user_id: session[:user_id]).
      update_name(name:)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end