# v3.0

class HawthorneCore::User::SessionController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  before_action :validate_signed_out?, only: [
    :sign_in_show
  ]

  # -----------------------------------------------------------------------------

  # show the sign-in page ... also used for sign-up
  def sign_in_show
    @html_title = 'Sign In | Sign Up'
    @meta_description = 'Sign into your ' + HawthorneCore::Site.this_site_name + ' account'
  end

  # -----------------------------------------------------------------------------

  # sign-in the user
  def sign_in

    # ----------------------

    # get the page attributes
    email_address = params[:email_address].to_s.downcase.strip
    keep_signed_in = params[:keep_signed_in]

    # ----------------------

    # validate that the email address does not have a syntax error
    # if invalid, return back to the sign-in page
    unless email_address_syntax_valid?(email_address)
      @sign_in_failed = @email_address_failed = @email_address_syntax_error = true
      HawthorneCore::UserAction::Log.sign_in_failure(HawthorneCore::UserAction::FailureReason.email_syntax_error, { email_address: email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('sign_in_failed_turbo_frame', partial: '/hawthorne_core/partials/user/sign_in_failed') and return
    end

    # ----------------------

    # find the user to sign-in
    user = HawthorneCore::User.
      select(:user_id, :token, :email_address, :email_address_verified, :phone_number, :phone_number_verified, :pin, :pin_created_at, :pin_default_delivery, :pin_failed_attempts_count).
      find_by(email_address: email_address)

    # if the user exists, log that the user has accessed the site
    user.log_site_access_for_known_user if user

    # if a user does not exist ... create the user record - and in doing so, log that the user has accessed the site
    user = HawthorneCore::User.create_record(email_address, request.remote_ip, cookies[:user_session_token]) unless user

    # refresh the users pin (if needed)
    user.refresh_pin

    # if the users default pin delivery is via email ... send the pin via email
    HawthorneCore::Email::SendPinJob.perform_later(user.id, keep_signed_in) if user.pin_default_delivery_via_email?

    # if the users default pin delivery is via phone ... send the pin via text message
    HawthorneCore::Text::SendPinJob.perform_later(user.id) if user.pin_default_delivery_via_phone?

    # redirect the user to verify their pin
    redirect_to verify_pin_path(token: user.token, pin_delivery_method: user.pin_default_delivery, keep_signed_in: keep_signed_in)

    # ----------------------

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their pin, to sign-in / sign-up
  def verify_pin_show

    # get the page attributes
    user_token = params[:token]
    @pin_delivery_method = params[:pin_delivery_method]
    error_message = params[:error_message]

    # in the unexpected case where the users token is not present, return back to the sign-in page
    unless user_token.present?
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_pin_show', message: 'Token not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token
    @user = HawthorneCore::User.
      select(:user_id, :token, :email_address, :phone_number).
      find_by(token: user_token, deleted: false)

    # in the unexpected case where the user is not found, return back to the sign-in page
    unless @user
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_pin_show', message: 'User not found with token', token: user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # when the user attempts to verify their pin via magic link ...
    # if the pin is NOT verified, the user is re-directed to this action with an error message to be displayed
    if error_message.present?
      @verify_pin_failed = true
      @pin_expired = true if error_message == 'PIN_EXPIRED'
      @pin_max_failed_attempts_reached = true if error_message == 'PIN_MAX_FAILED_ATTEMPTS_REACHED'
      @pin_not_match = true if error_message == 'PIN_NOT_MATCH'
      @pin_not_set = true if error_message == 'PIN_NOT_SET'
    end

    @html_title = 'Verify Pin'

  end

  # -----------------------------------------------------------------------------

  # verify the users pin, to sign-in / sign-up
  def verify_pin

    # ----------------------

    # prior to verifying ... determine if the user is already signed in
    # this will be true when the user signs-in on a different tab - ex: clicks magic link
    redirect_to account_path and return if @signed_in

    # ----------------------

    # get the page attributes
    user_token = params[:token]
    pin = params[:pin]
    pin_delivery_method = params[:pin_delivery_method]
    from_magic_link = params[:from_magic_link]
    keep_signed_in = params[:keep_signed_in].to_i

    # ----------------------

    # in the unexpected case where the users token is not present, return back to the sign-in page
    unless user_token.present?
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_pin', message: 'Token not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token
    user = HawthorneCore::User.
      select(:user_id, :token, :pin, :pin_created_at, :pin_failed_attempts_count, :email_address, :email_address_verified).
      find_by(token: user_token, deleted: false)

    # in the unexpected case where the user is not found, return back to the sign-in page
    unless user
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_pin', message: 'Site User not found with token', token: user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # ----------------------

    # in the unexpected case where the pin delivery method is not an expected value, return back to the sign-in page
    unless HawthorneCore::User::PIN_DELIVERY_METHODS.include?(pin_delivery_method)
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_pin', message: 'Unexpected pin delivery method', pin_delivery_method: pin_delivery_method }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # ----------------------

    # in the unexpected case where the pin is not set ...
    # refresh the users pin, send it via the prior delivery method, then return back to the verify pin page
    unless user.pin_set?
      @verify_pin_failed = @pin_not_set = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_set, { pin: pin, pin_created_at: user.pin_created_at }, request.remote_ip, cookies[:user_session_token])
      user.refresh_pin_then_send_it(pin_delivery_method)
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: 'PIN_NOT_SET') and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # in the unexpected case where the pin is expired ...
    # refresh the users pin, send it via the prior delivery method, then return back to the verify pin page
    if user.pin_expired?
      @verify_pin_failed = @pin_expired = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { pin: pin, pin_created_at: user.pin_created_at }, request.remote_ip, cookies[:user_session_token])
      user.refresh_pin_then_send_it(pin_delivery_method)
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: 'PIN_EXPIRED') and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # in the unexpected case where the max number of failed attempts reached ...
    # refresh the users pin, send it via the prior delivery method, then return back to the verify pin page
    if user.pin_max_failed_attempts_reached?
      @verify_pin_failed = @pin_max_failed_attempts_reached = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_max_failed_attempts_reached, { pin: pin, pin_created_at: user.pin_created_at, pin_failed_attempts_count: user.pin_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user.refresh_pin_then_send_it(pin_delivery_method)
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: 'PIN_MAX_FAILED_ATTEMPTS_REACHED') and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # verify the pin - it is set, not expired, has not reached the max number of failed attempts
    # if the entered pin does not match, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users pin, send it via the prior delivery method
    # lastly, when the entered pin does not match, return back to the verify pin page
    unless user.pin_match?(pin)
      @verify_pin_failed = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { pin: pin, pin_to_match: user.pin }, request.remote_ip, cookies[:user_session_token])
      user.add_pin_failed_attempt
      if user.pin_max_failed_attempts_reached?
        @pin_max_failed_attempts_reached = true
        error_message = 'PIN_MAX_FAILED_ATTEMPTS_REACHED'
        user.refresh_pin_then_send_it(pin_delivery_method)
      else
        @pin_not_match = true
        error_message = 'PIN_NOT_MATCH'
      end
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: error_message) and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # ----------------------

    # the pin is verified!
    # clear the pin - it is one time use only
    HawthorneCore::UserAction::Log.pin_verified(user.id, request.remote_ip, cookies[:user_session_token])
    user.clear_pin

    # sign-in the user
    session[:user_id] = user.id
    HawthorneCore::UserAction::Log.sign_in(user.id)

    # verify the users email address (if the pin was sent via email and the users email address has not been verified prior)
    user.verify_email_address if pin_delivery_method == HawthorneCore::User::PIN_VIA_EMAIL

    # determine if this is the users first sign-in on this site
    # if true, a welcome email is sent
    first_sign_in_on_site = user.first_sign_in_on_site?

    # log the users site sign-in ...
    # this is a record for each user / site that captures the users first sign-in, last sign-in, and #sign-ins
    user.log_site_sign_in(keep_signed_in)

    # if this is the users first sign-in (on site) ... send the user a welcome email
    HawthorneCore::Email::SendWelcomeEmailJob.perform_later(user.id, user.email_address) if first_sign_in_on_site

    # create the user a stripe account (if not done prior)
    # TODO ... need to care if hawthorne site or not ... put this on the user site record?
    # user.create_stripe_account

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

end