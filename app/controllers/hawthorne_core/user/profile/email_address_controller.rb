# v3.0

class HawthorneCore::User::Profile::EmailAddressController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their email address
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # find the users site record ... the new email address attributes are specific to each site
    # then clear the users new email address attributes
    HawthorneCore::UserSite.
      select(:user_site_id, :user_id).
      find_by(user_id: @user.id, site_id: HawthorneCore::Site.this_site_id).
      clear_new_email_address_attrs

    # ----------------------

    @html_title = 'Update Email Address | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify the users email address, to update
  def verify

    # get the request attributes
    new_email_address = params[:new_email_address].to_s.downcase.strip

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email_address).
      active.
      find_by(user_id: session[:user_id])

    # find the users site record ... the new email address attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email_address).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # verify that the new email address does not have a syntax error
    # if invalid - log it, return back and display an error message
    unless HawthorneCore::Helpers::EmailAddress.syntax_valid?(new_email_address)
      HawthorneCore::UserAction::Log.update_profile_email_address_failure(user.id, HawthorneCore::UserAction::FailureReason.email_address_syntax_error, { new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_address_failed', locals: { syntax_error: true }) and return
    end

    # verify that the new email address does not match the current email address
    # if identical - log it, return back and display an error message
    if user.email_address == new_email_address
      HawthorneCore::UserAction::Log.update_profile_email_address_failure(user.id, HawthorneCore::UserAction::FailureReason.email_address_identical, { current_email_address: user.email_address, new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_address_failed', locals: { identical: true }) and return
    end

    # verify that the new email address is not taken
    # if taken - log it, return back and display an error message
    if HawthorneCore::Helpers::EmailAddress.taken?(new_email_address)
      HawthorneCore::UserAction::Log.update_profile_email_address_failure(user.id, HawthorneCore::UserAction::FailureReason.email_address_taken, { new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_address_failed', locals: { taken: true }) and return
    end

    # ----------------------

    # the new email address is valid!

    # set the users new email address attributes
    # the user needs to verify their new email address, via a pin, prior to updating their profile in the database
    user_site.set_new_email_address_attrs(new_email_address)

    # send the user an email with a pin to verify their new email address
    HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(user.id)

    # ----------------------

    redirect_to account_profile_email_address_verify_pin_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their pin, to update the email address
  def verify_pin_show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email_address, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # find the users new email address
    @new_email_address = HawthorneCore::UserSite.where(user_id: @user.id, site_id: HawthorneCore::Site.this_site_id).pick(:new_email_address)

    # ----------------------

    @html_title = 'Update Email Address | Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their pin, to update their email address
  def resend_pin
    HawthorneCore::Email::SendEmailAddressUpdatePinJob.perform_later(session[:user_id])
    redirect_to account_profile_email_address_verify_pin_path
  end

  # -----------------------------------------------------------------------------

  # verify the users pin, to update their email address
  def verify_pin

    # get the request attributes
    pin = params[:pin]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email_address).
      active.
      find_by(user_id: session[:user_id])

    # find the users site record ... the new email address attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email_address, :new_email_address_pin, :new_email_address_pin_created_at, :new_email_address_pin_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the pin is inactive ...
    # refresh the pin, resend, then return back and display an error message
    unless user_site.new_email_address_pin_active?
      (pin_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_not_set) unless user_site.new_email_address_pin_set?
      (pin_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_expired) if user_site.new_email_address_pin_expired?
      (pin_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached) if user_site.new_email_address_pin_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.update_profile_email_address_failure(user.id, failure_reason, { new_email_address_pin: user_site.new_email_address_pin, new_email_address_pin_created_at: user_site.new_email_address_pin_created_at, new_email_address_pin_failed_attempts_count: user_site.new_email_address_pin_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user_site.refresh_new_email_address_pin_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_set: pin_not_set, expired: pin_expired, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # verify the pin - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered pin does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users pin, resend
    # lastly, when the entered pin does not match, return back and display an error message
    unless user_site.new_email_address_pin_match?(pin)
      HawthorneCore::UserAction::Log.update_profile_email_address_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { entered_pin: pin, pin_to_match: user_site.new_email_address_pin }, request.remote_ip, cookies[:user_session_token])
      user_site.add_new_email_address_pin_failed_attempt
      if user_site.new_email_address_pin_max_failed_attempts_reached?
        pin_max_failed_attempts_reached = true
        user_site.refresh_new_email_address_pin_then_send_it
      else
        pin_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_match: pin_not_match, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # ----------------------

    # the pin is verified!

    # temporarily capture the old and new email addresses, for logging
    old_email_address = user.email_address
    new_email_address = user_site.new_email_address

    # update the users email address,
    # then clear the users update email address attributes
    user.update_columns(email_address: new_email_address)
    user_site.clear_new_email_address_attrs

    # log it
    HawthorneCore::UserAction::Log.update_profile_email_address(user.id, { old_email_address: old_email_address, new_email_address: new_email_address }, request.remote_ip, cookies[:user_session_token])

    # update the users email address, within stripe
    HawthorneCore::Stripe::UpdateCustomerEmailAddressJob.perform_later(user.id)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end