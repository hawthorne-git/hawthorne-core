# v3.0

class HawthorneCore::User::Profile::DeleteAccountController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to start the process, to delete their account
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # find the users site record ... the delete account attributes are specific to each site
    # then clear the users delete account attributes
    HawthorneCore::UserSite.
      select(:user_site_id, :user_id).
      find_by(user_id: @user.id, site_id: HawthorneCore::Site.this_site_id).
      clear_delete_account_attrs

    # ----------------------

    @html_title = 'Delete Account | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify that the user wants to delete their account
  def verify

    # find the users site record ... the delete account attributes are specific to each site
    # then clear the users delete account attributes
    HawthorneCore::UserSite.
      select(:user_site_id, :user_id).
      find_by(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).
      set_delete_account_attr

    # ----------------------

    # send the user an email with a code to verify that they want to delete their account
    HawthorneCore::Email::SendDeleteAccountCodeJob.perform_later(session[:user_id])

    # ----------------------

    redirect_to account_profile_delete_account_verify_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update their phone number
  def verify_code_show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Delete Account | Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to delete their account
  # as the show action sends the user their code - no need to here
  def resend_code
    HawthorneCore::Email::SendDeleteAccountCodeJob.perform_later(session[:user_id])
    redirect_to account_profile_delete_account_verify_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their email
  def verify_code

    # get the request attributes
    code = params[:code]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :token).
      active.
      find_by(user_id: session[:user_id])

    # find the users site record ... the new delete account attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :delete_account_code, :delete_account_code_created_at, :delete_account_code_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the code is inactive ...
    # refresh the code, resend, then return back and display an error message
    unless user_site.delete_account_code_active?
      (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.delete_account_code_set?
      (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.delete_account_code_expired?
      (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.delete_account_code_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.delete_account_failure(user.id, failure_reason, { delete_account_code: user_site.delete_account_code, delete_account_code_created_at: user_site.delete_account_code_created_at, delete_account_code_failed_attempts_count: user_site.delete_account_code_failed_attempts_count })
      user_site.refresh_delete_account_code_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { not_set: code_not_set, expired: code_expired, max_failed_attempts_reached: code_max_failed_attempts_reached }) and return
    end

    # verify the code - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered code does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users code, resend
    # lastly, when the entered code does not match, return back and display an error message
    unless user_site.delete_account_code_match?(code)
      HawthorneCore::UserAction::Log.delete_account_failure(user.id, HawthorneCore::UserAction::FailureReason.code_not_match, { entered_code: code, code_to_match: user_site.delete_account_code })
      user_site.add_delete_account_code_failed_attempt
      if user_site.delete_account_code_max_failed_attempts_reached?
        code_max_failed_attempts_reached = true
        user_site.refresh_delete_account_code_attrs_then_send_it
      else
        code_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { not_match: code_not_match, max_failed_attempts_reached: code_max_failed_attempts_reached }) and return
    end

    # ----------------------

    # the code is verified!

    # soft delete the account - the actual deletion is done via a cron job
    # set the users email to be their token
    user.soft_delete
    user.update_columns(email: user.token)

    # log it
    HawthorneCore::UserAction::Log.delete_account(user.id)

    # reset the session - logs the user out
    reset_session

    # ----------------------

    # redirect the user to a message noting that their account is deleted
    redirect_to account_deleted_path

  end

  # -----------------------------------------------------------------------------

end