# v3.0

class HawthorneCore::User::Profile::NameController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their name
  def show

    # find the users name
    @name = HawthorneCore::User.user_name(user_id:)

    # ----------------------

    @html_title = 'Name | Profile'

  end

  # -----------------------------------------------------------------------------

  # add / update the users name
  def update

    name = params[:name].to_s.squish

    # ----------------------

    # update the users name
    HawthorneCore::User.update_name(user_id:, name:)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end