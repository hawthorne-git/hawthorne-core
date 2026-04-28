# v3.0

class HawthorneCore::User::SessionController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to signing out
  before_action :user_signed_in?, only: [:sign_out]

  # verify that the user is signed out prior to all action, but signing out
  before_action :user_signed_out?, except: [:sign_out]

  # -----------------------------------------------------------------------------

  # show the sign-in page ... also used for sign-up
  def sign_in_show

    @html_title = 'Sign-In'

  end

  # -----------------------------------------------------------------------------

  # sign-in the user
  def sign_in

    # get the request attributes
    email = params[:email].to_s.downcase.strip
    keep_signed_in = params[:keep_signed_in]

    # ----------------------

    # verify that the email does not have a syntax error
    # if invalid - log it, return back and display an error message
    unless HawthorneCore::Helpers::Email.syntax_valid?(email)
      HawthorneCore::UserAction::Log.sign_in_failure(HawthorneCore::UserAction::FailureReason.email_syntax_error, { email: }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: 'sign_in_failed', locals: { syntax_error: true }) and return
    end

    # ----------------------

    # find the user to sign-in
    # find the user by their email with the site sharing scope
    # note that a user will have a single (and shared) Hawthorne account ... but alt sites (ex: William Morris) may be stand-alone
    user = HawthorneCore::User.
      select(:user_id, :token, :email, :phone_number, :sign_in_code_default_delivery).
      active.
      find_by(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)

    # if the user exists, log that the user has accessed the site
    # else, create the user then log that the user has accessed the site (as a new user) - log that an account was created
    if user
      user.log_site_access_for_known_user
    else
      user = HawthorneCore::User.create!(email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)
      user.log_site_access_for_new_user
      HawthorneCore::UserAction::Log.account_created(user.id, { email:, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope }, request.remote_ip, cookies[:user_session_token])
    end

    # find the users site record ... the sign-in code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :site_id, :user_id, :sign_in_code, :sign_in_code_created_at, :sign_in_code_failed_attempts_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # refresh the users sign-in code (for site)
    user_site.refresh_sign_in_code

    # send the user their sign-in code via default delivery, email or text
    HawthorneCore::Email::SendSignInCodeJob.perform_later(user.id, keep_signed_in) if user.sign_in_code_default_delivery_via_email?
    HawthorneCore::Text::SendSignInCodeJob.perform_later(user.id) if user.sign_in_code_default_delivery_via_phone?

    # redirect the user to verify their sign-in code
    redirect_to verify_sign_in_code_path(token: user.token, code_delivery_method: user.sign_in_code_default_delivery, keep_signed_in: keep_signed_in)

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their sign-in code
  def verify_sign_in_code_show

    # get the request attributes
    @user_token = params[:token]
    @code_delivery_method = params[:code_delivery_method]
    @keep_signed_in = params[:keep_signed_in].to_i
    error_message = params[:error_message]

    # ----------------------

    # in the unexpected case where the users token is not present - log it, return back to the sign-in page
    unless @user_token.present?
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_code_show', message: 'Token not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token
    @user = HawthorneCore::User.
      select(:user_id, :token, :email, :email_verified, :phone_number).
      active.
      find_by(token: @user_token)

    # in the unexpected case where the user is not found - log it, return back to the sign-in page
    unless @user
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_code_show', message: 'User not found with token', token: @user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # ----------------------

    # when the user attempts to verify their code via magic link (sent in an email) ...
    # if the code is NOT verified, the user is re-directed to this action to display an error message
    if error_message.present?
      @verify_code_failed = true
      @code_expired = true if error_message == 'CODE_EXPIRED'
      @code_max_failed_attempts_reached = true if error_message == 'CODE_MAX_FAILED_ATTEMPTS_REACHED'
      @code_not_match = true if error_message == 'CODE_NOT_MATCH'
      @code_not_set = true if error_message == 'CODE_NOT_SET'
    end

    # ----------------------

    @html_title = 'Verify Sign-In Code'

  end

  # -----------------------------------------------------------------------------

  # resend the user their sign-in code via delivery method
  def resend_sign_in_code

    # get the request attributes
    user_token = params[:token]
    code_delivery_method = params[:code_delivery_method]
    keep_signed_in = params[:keep_signed_in]

    # ----------------------

    # find the user by their token
    user = HawthorneCore::User.
      select(:user_id).
      active.
      find_by(token: user_token)

    # send the user their code via prior delivery method, email or text
    HawthorneCore::Email::SendSignInCodeJob.perform_later(user.id, keep_signed_in) if code_delivery_method == HawthorneCore::User::CODE_VIA_EMAIL
    HawthorneCore::Text::SendSignInCodeJob.perform_later(user.id) if code_delivery_method == HawthorneCore::User::CODE_VIA_PHONE

    # ----------------------

    # redirect the user to verify their code
    redirect_to verify_sign_in_code_path(token: user_token, code_delivery_method: code_delivery_method, keep_signed_in: keep_signed_in)

  end

  # -----------------------------------------------------------------------------

  # resend the user their sign-in code via email
  def resend_sign_in_code_via_email = redirect_to resend_sign_in_code_path(token: params[:token], code_delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: params[:keep_signed_in])

  # resend the user their sign-in code via text message
  def resend_sign_in_code_via_phone = redirect_to resend_sign_in_code_path(token: params[:token], code_delivery_method: HawthorneCore::User::CODE_VIA_PHONE, keep_signed_in: params[:keep_signed_in])

  # -----------------------------------------------------------------------------

  # verify the users sign-in code
  def verify_sign_in_code

    # ----------------------

    # get the request attributes
    user_token = params[:token]
    code = params[:code]
    code_delivery_method = params[:code_delivery_method]
    from_magic_link = params[:from_magic_link]
    keep_signed_in = params[:keep_signed_in].to_i

    # ----------------------

    # in the unexpected case where the users token is not present - log it, return back to the sign-in page
    unless user_token.present?
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_code', message: 'Token not present' }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the user by their token
    user = HawthorneCore::User.
      select(:user_id, :token, :email, :email_verified, :stripe_customer_id).
      active.
      find_by(token: user_token)

    # in the unexpected case where the user is not found (by their token) - log it, return back to the sign-in page
    unless user
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_code', message: 'Site User not found with token', token: user_token }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # find the users site record ... the sign-in code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :site_id, :user_id, :sign_in_code, :sign_in_code_created_at, :sign_in_code_failed_attempts_count, :sign_in_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # in the unexpected case where the code delivery method is not an expected value - log it, return back to the sign-in page
    unless HawthorneCore::User::SIGN_IN_CODE_DELIVERY_METHODS.include?(code_delivery_method)
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { controller_action: 'verify_code', message: 'Unexpected code delivery method', code_delivery_method: code_delivery_method }, request.remote_ip, cookies[:user_session_token])
      redirect_to sign_in_path and return
    end

    # ----------------------

    # if the code is inactive ...
    # refresh the code, resend, then return back and display an error message
    unless user_site.sign_in_code_active?
      (code_not_set = true; error_message = 'CODE_NOT_SET'; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.sign_in_code_set?
      (code_expired = true; error_message = 'CODE_EXPIRED'; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.sign_in_code_expired?
      (code_max_failed_attempts_reached = true; error_message = 'CODE_MAX_FAILED_ATTEMPTS_REACHED'; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.sign_in_code_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(user.id, failure_reason, { sign_in_code: user_site.sign_in_code, sign_in_code_created_at: user_site.sign_in_code_created_at, sign_in_code_failed_attempts_count: user_site.sign_in_code_failed_attempts_count }, request.remote_ip, cookies[:user_session_token])
      user_site.refresh_sign_in_code_then_send_it(code_delivery_method, keep_signed_in)
      redirect_to verify_sign_in_code_path(token: user.token, code_delivery_method: code_delivery_method, keep_signed_in: keep_signed_in, error_message: error_message) and return if from_magic_link
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: }) and return
    end

    # verify the code - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered code does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users code, resend
    # lastly, when the entered code does not match, return back and display an error message
    unless user_site.sign_in_code_match?(code)
      HawthorneCore::UserAction::Log.sign_in_code_verified_failure(user.id, HawthorneCore::UserAction::FailureReason.code_not_match, { code:, code_to_match: user_site.sign_in_code }, request.remote_ip, cookies[:user_session_token])
      user_site.add_sign_in_code_failed_attempt
      if user_site.sign_in_code_max_failed_attempts_reached?
        code_max_failed_attempts_reached = true; error_message = 'CODE_MAX_FAILED_ATTEMPTS_REACHED'
        user_site.refresh_sign_in_code_then_send_it(code_delivery_method, keep_signed_in)
      else
        code_not_match = true; error_message = 'CODE_NOT_MATCH'
      end
      redirect_to verify_sign_in_code_path(token: user.token, code_delivery_method: code_delivery_method, keep_signed_in: keep_signed_in, error_message: error_message) and return if from_magic_link
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match:, code_max_failed_attempts_reached: }) and return
    end

    # ----------------------

    # the code is verified - log it
    # clear the sign-in code - it is one time use only
    HawthorneCore::UserAction::Log.sign_in_code_verified(user.id, request.remote_ip, cookies[:user_session_token])
    user_site.clear_sign_in_code

    # sign-in the user - log it
    session[:user_id] = user.id
    HawthorneCore::UserAction::Log.sign_in(user.id)

    # attach the user to their session
    HawthorneCore::UserSession.find_by(token: cookies[:user_session_token])&.update_columns(user_id:)

    # verify the users email (if the code was sent via email)
    user.verify_email if code_delivery_method == HawthorneCore::User::CODE_VIA_EMAIL

    # determine if this is the users first sign-in on this site
    # if true, a welcome email is sent
    first_sign_in_on_site = user_site.first_sign_in?

    # log the users site sign-in ...
    # this is a record for each user / site that captures the users first sign-in, last sign-in, #sign-ins, and if they should be kept as signed in
    user.log_site_sign_in(keep_signed_in: keep_signed_in)

    # if this is the users first sign-in (on site) ... send the user a welcome email
    HawthorneCore::Email::SendWelcomeEmailJob.perform_later(user.id) if first_sign_in_on_site

    # create the user a stripe customer account (if not done prior)
    HawthorneCore::Stripe::CreateCustomerJob.perform_later(user.id) unless user.stripe_customer?

    # TODO: if first sign-in EVER, redirect to enter phone number? or maybe on their third sign-in?

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  # sign-out the user
  def sign_out

    # update the user / site record, as the user is forcing a sign-out - remove ability to keep signed in via cookie
    HawthorneCore::UserSite.log_site_sign_out(session[:user_id])

    # log that the user has signed out
    HawthorneCore::UserAction::Log.sign_out(session[:user_id], request.remote_ip, cookies[:user_session_token])

    # reset the session
    reset_session

    # redirect the user to the sites home page
    redirect_to('/')

  end

  # -----------------------------------------------------------------------------

end