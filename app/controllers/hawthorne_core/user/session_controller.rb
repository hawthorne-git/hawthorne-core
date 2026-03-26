# v3.0XXX

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
    user.log_site_access_for_user if user

    # if a user does not exist ... create the user record - and in doing so, log that the user has accessed the site
    user = HawthorneCore::User.create_record(email_address, request.remote_ip, cookies[:user_session_token]) unless user

    # refresh the users pin (if needed)
    user.refresh_pin

    # if the users default pin delivery is via email ... send the pin via email
    HawthorneCore::Email::SendPinJob.perform_later(user.id) if user.pin_default_delivery_via_email?

    return if true

    # if the users default pin delivery is via phone ... send the pin via text message
    HawthorneCore::Text::SendPinJob.perform_later(user.id) if user.pin_default_delivery_via_phone?

    # redirect the user to verify their pin
    redirect_to verify_pin_path(token: user.token, pin_delivery_method: user.pin_default_delivery)

    # ----------------------

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their pin, to sign-in / sign-up
  def verify_pin_show

    # get the page attributes
    user_token = params[:token]
    @pin_delivery_method = params[:pin_delivery_method]
    error_message = params[:error_message]

    # in the unexpected case where the users token (small web id) is not present, return back to the sign-in page
    unless user_token.present?
      HawthorneCore::UserAction::Log.verify_sign_in_pin_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { action: 'verify_sign_in_pin_show', message: 'Token parameter not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token (small web id)
    @user = HawthorneCore::User.
      select(:user_id, :small_web_id, :email_address, :phone_number).
      find_by(small_web_id: user_token, deleted: false)

    # in the unexpected case where the user is not found, return back to the sign-in page
    unless @user
      HawthorneCore::UserAction::Log.verify_sign_in_pin_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { action: 'verify_sign_in_pin_show', message: 'Site User not found with token', small_web_id: user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # when the user attempts to verify their pin via magic link ...
    # if the pin is NOT verified, the user is re-directed to this action with an error message
    if error_message.present?
      @verify_pin_failed = true
      @pin_inactive = true if error_message == 'PIN_INACTIVE'
      @max_allowed_pin_attempts_reached = true if error_message == 'MAX_PIN_ATTEMPTS_REACHED'
      @pin_does_not_match = true if error_message == 'PIN_DOES_NOT_MATCH'
    end

    @html_title = 'Verify Pin'

  end

  # -----------------------------------------------------------------------------

  # verify the users pin, to sign-in / sign-up
  def verify_pin

    # get the page attributes
    user_token = params[:token]
    pin = params[:pin]
    pin_delivery_method = params[:pin_delivery_method]
    from_magic_link = params[:from_magic_link]

    # in the unexpected case where the users token (small web id) is not present, return back to the sign-in page
    unless user_token.present?
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { action: 'verify_sign_in_pin', message: 'Token parameter not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token (small web id)
    user = HawthorneCore::User.
      select(:user_id, :small_web_id, :pin, :pin_created_at, :nbr_failed_pin_attempts, :email_address, :email_address_verified, :phone_number_verified, :braintree_id).
      find_by(small_web_id: user_token, deleted: false)

    # in the unexpected case where the user is not found, return back to the sign-in page
    unless user
      HawthorneCore::UserAction::Log.pin_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { action: 'verify_sign_in_pin', message: 'Site User not found with token', small_web_id: user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # in the unexpected case where the pin delivery method is not an expected value, set it to email
    unless HawthorneCore::User::PIN_DELIVERY_METHODS.include?(pin_delivery_method)
      HawthorneCore::CapturedException.log('HawthorneCore::User::SessionController.verify_pin', { message: 'unexpected pin_delivery_method value', pin_delivery_method: pin_delivery_method, user_id: user.id }, nil)
      pin_delivery_method = HawthorneCore::User::PIN_VIA_EMAIL
    end

    # verify the pin is active
    # if invalid, refresh their pin then send it via the prior delivery method, then return back to the verify pin page
    unless user.pin_active?
      @verify_pin_failed = @pin_inactive = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { pin: pin, pin_created_at: user.pin_created_at }, request.remote_ip, cookies[:user_session_token])
      user.refresh_pin_then_send_it(pin_delivery_method)
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: 'PIN_INACTIVE') and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # verify the pin
    # if invalid, increment the number of failed attempts, then return back to the verify pin page
    # if the max number of failed attempts reached, refresh their pin and send it prior to returning
    unless user.pin_match?(pin)
      @verify_pin_failed = true
      HawthorneCore::UserAction::Log.pin_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { pin: pin, pin_to_match: user.pin }, request.remote_ip, cookies[:user_session_token])
      user.add_failed_pin_attempt
      if user.reached_max_allowed_pin_attempts?
        @max_allowed_pin_attempts_reached = true
        error_message = 'MAX_PIN_ATTEMPTS_REACHED'
        user.refresh_pin_then_send_it(pin_delivery_method)
      else
        @pin_does_not_match = true
        error_message = 'PIN_DOES_NOT_MATCH'
      end
      redirect_to verify_pin_path(token: user.token, pin_delivery_method: pin_delivery_method, error_message: error_message) and return if from_magic_link
      render turbo_stream: turbo_stream.update('verify_pin_failed_turbo_frame', partial: '/hawthorne_core/partials/user/verify_pin_failed') and return
    end

    # the pin is verified!
    # clear the pin - one time use only
    HawthorneCore::UserAction::Log.pin_verified(user.id, request.remote_ip, cookies[:user_session_token])
    user.clear_pin

    # sign-in the user
    session[:user_id] = user.id
    HawthorneCore::UserAction::Log.sign_in(user.id)

    # determine if this is the users first sign-in
    first_sign_in = user.first_sign_in?

    # verify the users email address (if not done prior)
    # create the user a braintree account (if not done prior)
    user.verify_email_address
    # user.create_braintree_account

    # if this is the users first sign-in (on site) ...
    # send the user a welcome email
    if first_sign_in
      # CoreJobs::Email::SendWelcomeEmailJob.perform_later(user_id, email_address)
    end

  end

  # -----------------------------------------------------------------------------

end