# v3.0

class HawthorneCore::User::Profile::DeleteAccountController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to start the process, to delete their account
  def show

    # find the users site record ... the delete account attributes are specific to each site
    # then clear the users delete account attributes
    HawthorneCore::UserSite.
      select(:user_site_id, :user_id).
      find_by(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).
      clear_delete_account_attrs

    # ----------------------

    @html_title = 'Delete Account | My Profile'

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

    # send the user an email with a pin to verify that they want to delete their account
    HawthorneCore::Email::SendDeleteAccountPinJob.perform_later(session[:user_id])

    # ----------------------

    redirect_to account_profile_delete_account_verify_pin_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their pin, to update their phone number
  def verify_pin_show

    # find the users email address
    @email_address = HawthorneCore::User.active.where(user_id: session[:user_id]).pick(:email_address)

    # ----------------------

    @html_title = 'Delete Account | My Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their pin, to delete their account
  # as the show action sends the user their pin - no need to here
  def resend_pin = redirect_to account_profile_delete_account_path(resend_pin: true)

  # -----------------------------------------------------------------------------

  # verify the users pin, to update their email address
  def verify_pin

    # get the request attributes
    pin = params[:pin]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :token).
      find_by(user_id: session[:user_id])

    # find the users site record ... the new delete account attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :delete_account_pin, :delete_account_pin_created_at, :delete_account_pin_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the pin is inactive ...
    # refresh the pin, resend, then return back and display an error message
    unless user_site.delete_account_pin_active?
      (pin_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_not_set) unless user_site.delete_account_pin_set?
      (pin_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_expired) if user_site.delete_account_pin_expired?
      (pin_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached) if user_site.delete_account_pin_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.delete_account_failure(user.id, failure_reason, { delete_account_pin: user_site.delete_account_pin, delete_account_pin_created_at: user_site.delete_account_pin_created_at, delete_account_pin_failed_attempts_count: user_site.delete_account_pin_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user_site.refresh_delete_account_pin_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_set: pin_not_set, expired: pin_expired, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # verify the pin - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered pin does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users pin, resend
    # lastly, when the entered pin does not match, return back and display an error message
    unless user_site.delete_account_pin_match?(pin)
      HawthorneCore::UserAction::Log.delete_account_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { entered_pin: pin, pin_to_match: user_site.delete_account_pin }, request.remote_ip, cookies[:user_session_token])
      user_site.add_delete_account_pin_failed_attempt
      if user_site.delete_account_pin_max_failed_attempts_reached?
        pin_max_failed_attempts_reached = true
        user_site.refresh_delete_account_pin_attrs_then_send_it
      else
        pin_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_match: pin_not_match, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # ----------------------

    # the pin is verified!

    # soft delete the account - the actual deletion is done via a cron job
    # set the users email address to be their token
    user.soft_delete
    user.update_columns(email_address: user.token)

    # log it
    HawthorneCore::UserAction::Log.delete_account(user.id, request.remote_ip, cookies[:user_session_token])

    # reset the session - logs the user out
    reset_session

    # ----------------------

    # redirect the user to a message noting that their account is deleted
    redirect_to account_deleted_path

  end

  # -----------------------------------------------------------------------------

end