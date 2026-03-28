# v3.0

class HawthorneCore::User::ProfileEmailAddressUpdateController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?
  
  # -----------------------------------------------------------------------------

  # show the page for the user to update their email address
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address).
      find_by(user_id: session[:user_id])

    # clear the users email address update attributes
    @user.clear_email_address_update_attrs

    # ----------------------

    @html_title = 'Update Email Address | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: profile_path },
      { title: 'Update Email Address', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # verify the users email address, to update
  def verify

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

  # show the page for the user to verify their pin, to update the email address
  def verify_pin_show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :new_email_address).
      find_by(user_id: session[:user_id])

    # ----------------------

    @html_title = 'Update Email Address | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: profile_path },
      { title: 'Update Email Address', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # resend the user their pin, to update the email address
  def resend_pin
    HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(session[:user_id])
    redirect_to profile_email_address_update_verify_pin_path
  end

  # -----------------------------------------------------------------------------

  # verify the users pin, to update the email address
  def verify_pin

    # get the page attributes
    pin = params[:pin]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email_address, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: session[:user_id])

    # ----------------------

    # in the unexpected case where the pin is not set - log it
    # refresh the users pin, email the pin, then return back and display an error message
    unless user.email_address_update_pin_set?
      @verify_pin_failed = @pin_not_set = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_set, { new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at }, request.remote_ip, cookies[:user_session_token])
      user.refresh_email_address_update_pin_then_send_it
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # in the unexpected case where the pin is expired - log it
    # refresh the users pin, email the pin, then return back and display an error message
    if user.email_address_update_pin_expired?
      @verify_pin_failed = @pin_expired = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at }, request.remote_ip, cookies[:user_session_token])
      user.refresh_email_address_update_pin_then_send_it
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # in the unexpected case where the max number of failed attempts reached - log it
    # refresh the users pin, email the pin, then return back and display an error message
    if user.email_address_update_pin_max_failed_attempts_reached?
      @verify_pin_failed = @pin_max_failed_attempts_reached = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached, { new_email_address_pin: user.new_email_address_pin, new_email_address_pin_created_at: user.new_email_address_pin_created_at, new_email_address_pin_failed_attempts_count: user.new_email_address_pin_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user.refresh_email_address_update_pin_then_send_it
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # verify the pin - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered pin does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users pin, email the pin
    # lastly, when the entered pin does not match, return back and display an error message
    unless user.email_address_update_pin_match?(pin)
      @verify_pin_failed = true
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { entered_pin: pin, pin_to_match: user.new_email_address_pin }, request.remote_ip, cookies[:user_session_token])
      user.add_email_address_update_pin_failed_attempt
      if user.email_address_update_pin_max_failed_attempts_reached?
        @pin_max_failed_attempts_reached = true
        user.refresh_email_address_update_pin_then_send_it
      else
        @pin_not_match = true
      end
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # ----------------------

    # the pin is verified!

    # temporarily capture the old and new email addresses, for logging
    old_email_address = user.email_address
    new_email_address = user.new_email_address

    # update the users email address,
    # then clear the users update email address attributes
    user.update_columns(email_address: new_email_address)
    user.clear_email_address_update_attrs

    # log it
    HawthorneCore::UserAction::Log.update_profile_email(user.id, { old_email_address: old_email_address, new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

end