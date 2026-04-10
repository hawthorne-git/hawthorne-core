# v3.0

class HawthorneCore::User::Profile::FullNameController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # action for the user to edit their full name
  def edit

    # get the request attributes
    full_name = params[:full_name]

    # ----------------------

    # find the user, then update their full name
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      update_column(:full_name, full_name)

    # log it
    HawthorneCore::UserAction::Log.update_profile(session[:user_id], {full_name: full_name}, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

end