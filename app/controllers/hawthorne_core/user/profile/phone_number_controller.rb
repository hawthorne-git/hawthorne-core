# v3.0

class HawthorneCore::User::Profile::PhoneNumberController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in prior to all actions
  before_action :verify_signed_in?

  # ----------------------------------------------------------------------------- 

  # show the page for the user to update their phone number
  def show

    # find the users phone number
    @current_phone_number = HawthorneCore::User.where(user_id: session[:user_id]).pick(:phone_number)

    # find the users site record ... the new phone number attributes are specific to each site
    # then clear the users new phone number attributes
    HawthorneCore::UserSite.
      select(:user_site_id, :user_id).
      find_by(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).
      clear_new_phone_number_attrs

    # ----------------------

    @html_title = 'Update Phone Number | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: account_profile_path },
      { title: 'Update Phone Number', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # verify the users new phone number
  def verify

    # get the request attributes
    new_phone_number = params[:new_phone_number].to_s.strip

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :phone_number).
      find_by(user_id: session[:user_id])

    # find the users site record ... the new phone number attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_phone_number).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # verify that the new phone number does not have a syntax error
    # if invalid - log it, return back and display an error message
    unless HawthorneCore::Helpers::PhoneNumber.us_syntax_valid?(new_phone_number)
      HawthorneCore::UserAction::Log.update_profile_phone_number_failure(user.id, HawthorneCore::UserAction::FailureReason.phone_number_syntax_error, { new_phone_number: new_phone_number }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_phone_number_failed', locals: { syntax_error: true }) and return
    end

    # verify that the new phone number does not match the current phone number
    # if identical - log it, return back and display an error message
    if HawthorneCore::Helpers::PhoneNumber.match?(user.phone_number, new_phone_number)
      HawthorneCore::UserAction::Log.update_profile_phone_number_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.phone_number_identical, { current_phone_number: user.phone_number, new_phone_number: new_phone_number }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_phone_number_failed', locals: { identical: true }) and return
    end

    # ----------------------

    # the new phone number is valid!

    # set the users new phone number attributes
    # the user needs to verify their new phone number, via a pin, prior to updating their profile in the database
    user_site.set_new_phone_number_attrs(new_phone_number)

    # send the user a text message with a pin to verify their new phone number
    HawthorneCore::Text::SendPhoneNumberUpdatePinJob.perform_later(user.id)

    # ----------------------

    redirect_to account_profile_phone_number_verify_pin_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their pin, to update their phone number
  def verify_pin_show

    # find the users current and new phone numbers
    @current_phone_number = HawthorneCore::User.where(user_id: session[:user_id]).pick(:phone_number)
    @new_phone_number = HawthorneCore::UserSite.where(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).pick(:new_phone_number)

    # ----------------------

    @html_title = 'Update Phone Number | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Profile', link: account_profile_path },
      { title: 'Update Phone Number', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # resend the user their pin, to update their phone number
  def resend_pin
    HawthorneCore::Text::SendPhoneNumberUpdatePinJob.perform_later(session[:user_id])
    redirect_to account_profile_phone_number_verify_pin_path
  end

  # -----------------------------------------------------------------------------

  # verify the users pin, to update their phone number
  def verify_pin

    # get the request attributes
    pin = params[:pin]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :phone_number).
      find_by(user_id: session[:user_id])

    # find the users site record ... the new phone number attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_phone_number, :new_phone_number_pin, :new_phone_number_pin_created_at, :new_phone_number_pin_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the pin is inactive ...
    # refresh the pin, resend, then return back and display an error message
    unless user_site.new_phone_number_pin_active?
      (pin_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_not_set) unless user_site.new_phone_number_pin_set?
      (pin_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_expired) if user_site.new_phone_number_pin_expired?
      (pin_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached) if user_site.new_phone_number_pin_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.update_profile_phone_number_failure(user.id, failure_reason, { new_phone_number_pin: user_site.new_phone_number_pin, new_phone_number_pin_created_at: user_site.new_phone_number_pin_created_at, new_phone_number_pin_failed_attempts_count: user_site.new_phone_number_pin_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user_site.refresh_new_phone_number_pin_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_set: pin_not_set, expired: pin_expired, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # verify the pin - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered pin does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users pin, resend
    # lastly, when the entered pin does not match, return back and display an error message
    unless user_site.new_phone_number_pin_match?(pin)
      HawthorneCore::UserAction::Log.update_profile_phone_number_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { entered_pin: pin, pin_to_match: user_site.new_phone_number_pin }, request.remote_ip, cookies[:user_session_token])
      user_site.add_new_phone_number_pin_failed_attempt
      if user_site.new_phone_number_pin_max_failed_attempts_reached?
        pin_max_failed_attempts_reached = true
        user.refresh_new_phone_number_pin_attrs_then_send_it
      else
        pin_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_pin_failed', locals: { not_match: pin_not_match, max_failed_attempts_reached: pin_max_failed_attempts_reached }) and return
    end

    # ----------------------

    # the pin is verified!

    # temporarily capture the old and new phone numbers, for logging
    old_phone_number = user.phone_number
    new_phone_number = user_site.new_phone_number

    # update the users phone number and set this as default delivery
    # then clear the users new phone number attributes, for site
    user.update_columns(phone_number: new_phone_number, sign_in_pin_default_delivery: HawthorneCore::User::PIN_VIA_PHONE)
    user_site.clear_new_phone_number_attrs

    # log it
    HawthorneCore::UserAction::Log.update_profile_phone_number(user.id, { old_phone_number: old_phone_number, new_phone_number: new_phone_number }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  # clear the users phone number
  def clear

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :phone_number).
      find_by(user_id: session[:user_id])

    # ----------------------

    # temporarily capture the old phone numbers, for logging
    old_phone_number = user.phone_number

    # clear the users phone number
    user.clear_phone_number

    # log it
    HawthorneCore::UserAction::Log.update_profile_phone_number(user.id, { old_phone_number: old_phone_number, new_phone_number: nil }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

end