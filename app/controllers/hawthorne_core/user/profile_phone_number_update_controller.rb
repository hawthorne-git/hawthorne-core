# v3.0

class HawthorneCore::User::ProfilePhoneNumberUpdateController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?

  # ----------------------------------------------------------------------------- 

  # show the page for the user to update their phone number
  def update_show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :phone_number).
      find_by(user_id: session[:user_id])

    # clear the users phone number update attributes
    @user.clear_phone_number_update_attrs

    # ----------------------

    @html_title = 'Update Phone Number | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: profile_path },
      { title: 'Update Phone Number', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # verify the users phone number, to update
  def update_validation

    # get the page attributes
    new_email_address = params[:new_email_address].to_s.downcase.strip

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email_address, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: session[:user_id])

    # ----------------------

    # verify that the new email address does not have a syntax error
    # if invalid - log it, return back and display an error message
    unless email_address_syntax_valid?(new_email_address)
      @update_email_address_failed = @new_email_address_syntax_error = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.email_syntax_error, { new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('update_email_address_failed_turbo_frame', partial: '/hawthorne_core/partials/user/update_email_address_failed') and return
    end

    # verify that the new email address does not match the current email address
    # if identical - log it, return back and display an error message
    if user.email_address == new_email_address
      @update_email_address_failed = @new_email_address_identical = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.email_identical, { current_email_address: user.email_address, new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('update_email_address_failed_turbo_frame', partial: '/hawthorne_core/partials/user/update_email_address_failed') and return
    end

    # verify that the new email address is not taken
    # if taken - log it, return back and display an error message
    if HawthorneCore::User.exists?(email_address: new_email_address)
      @update_email_address_failed = @new_email_address_taken = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.email_taken, { new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('update_email_address_failed_turbo_frame', partial: '/hawthorne_core/partials/user/update_email_address_failed') and return
    end

    # ----------------------

    # the new email address is valid!

    # set the users email address update attributes
    # the user needs to verify their new email address, via a pin, prior to updating their profile in the database
    user.set_email_address_update_attrs(new_email_address)

    # send the user an email with a pin to verify their new email address
    HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(user.id)

    # ----------------------

    redirect_to profile_email_address_update_verify_pin_path

  end

  # -----------------------------------------------------------------------------

end