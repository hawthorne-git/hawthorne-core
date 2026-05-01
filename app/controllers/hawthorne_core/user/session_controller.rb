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

    email = params[:email].to_s.strip.downcase
    keep_signed_in = params[:keep_signed_in]

    # ----------------------

    # verify that the email does not have a syntax error
    return render_email_syntax_error(email:) unless HawthorneCore::Helpers::Email.syntax_valid?(email:)

    # ----------------------

    # find (or create) the user
    # set the users sign-in attributes
    user = HawthorneCore::User.find_or_create(email:)
    user.set_sign_in_attrs

    # send the user their code via default delivery method, email or text
    send_sign_in_code(delivery_method: user.sign_in_code_default_delivery, user_id: user.id, keep_signed_in:)

    # ----------------------

    # redirect the user to verify their sign-in code
    redirect_to verify_sign_in_code_path(token: user.token, delivery_method: user.sign_in_code_default_delivery, keep_signed_in:)

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their sign-in code
  def verify_code_show

    @token = token = params[:token]
    @delivery_method = params[:delivery_method]
    @keep_signed_in = params[:keep_signed_in].to_i

    # ----------------------

    # in the unexpected case where the user is not found, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'verify_code_show', token:) unless HawthorneCore::User.exists_with_token?(token:)

    # ----------------------

    # find the users email and phone number
    @email, @phone_number = HawthorneCore::User.
      active.
      where(token:).
      pick(:email, :phone_number)

    # ----------------------

    @html_title = 'Verify Sign-In Code'

  end

  # -----------------------------------------------------------------------------

  # resend the user their sign-in code via delivery method
  def resend_code

    token = params[:token]
    delivery_method = params[:delivery_method]
    keep_signed_in = params[:keep_signed_in]

    # ----------------------

    # in the unexpected case where the user is not found, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'resend_code', token:) unless HawthorneCore::User.exists_with_token?(token:)

    # ----------------------

    # find the user id by their token
    user_id = HawthorneCore::User.user_id_for_token(token:)

    # send the user their code via prior delivery method, email or text
    send_sign_in_code(delivery_method:, user_id:, keep_signed_in:)

    # ----------------------

    # redirect the user to verify their code
    redirect_to verify_sign_in_code_path(token:, delivery_method:, keep_signed_in:)

  end

  # -----------------------------------------------------------------------------

  # resend the user their sign-in code via email / text message
  def resend_code_via_email = redirect_to resend_sign_in_code_path(token: params[:token], delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: params[:keep_signed_in])
  def resend_code_via_phone = redirect_to resend_sign_in_code_path(token: params[:token], delivery_method: HawthorneCore::User::CODE_VIA_PHONE, keep_signed_in: params[:keep_signed_in])

  # -----------------------------------------------------------------------------

  # verify the users sign-in code
  def verify_code

    token = params[:token]
    code = params[:code]
    delivery_method = params[:delivery_method]
    from_magic_link = params[:from_magic_link]
    keep_signed_in = params[:keep_signed_in].to_i

    # ----------------------

    # in the unexpected case where the user is not found or the code delivery method is an unexpected value, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'verify_sign_in_code', token:) unless HawthorneCore::User.exists_with_token?(token:)
    return redirect_to_sign_in_when_delivery_method_unexpected(method: 'verify_sign_in_code', delivery_method:, token:) unless HawthorneCore::User::sign_in_code_delivery_methods.include?(delivery_method)

    # ----------------------

    # find the user id by their token
    user_id = HawthorneCore::User.user_id_for_token(token:)

    # find the users site record ... the sign-in code is specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :sign_in_code, :sign_in_code_created_at, :sign_in_code_failed_attempts_count, :sign_in_count).
      find_by(user_id:, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # verify that the code is active, and matches
    return render_code_inactive_error(user_site:, delivery_method:, keep_signed_in:) unless user_site.sign_in_code_active?
    return render_code_not_match_error(user_site:, code:, delivery_method:, keep_signed_in:) unless user_site.sign_in_code_match?(code:)

    # ----------------------

    # the code is verified

    # sign-in the user
    HawthorneCore::User.
      select(:user_id, :email_verified, :stripe_customer_id).
      find_by(user_id:).
      sign_in(user_session_token: cookies[:user_session_token], keep_signed_in:)

    # set the user into the session
    session[:user_id] = user_id

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  # sign-out the user
  def sign_out

    # sign-out the user
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      sign_out

    # reset the session
    reset_session

    # ----------------------

    # redirect the user to the sites home page
    redirect_to('/')

  end

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  private

  # ------------------------

  # send the user their sign-in code, via delivery method
  def send_sign_in_code(delivery_method:, user_id:, keep_signed_in:)
    HawthorneCore::Email::SendSignInCodeJob.perform_later(user_id:, keep_signed_in:) if delivery_method == HawthorneCore::User::CODE_VIA_EMAIL
    HawthorneCore::Text::SendSignInCodeJob.perform_later(user_id:) if delivery_method == HawthorneCore::User::CODE_VIA_PHONE
  end

  # ------------------------

  # redirect the user to the sign-in page when the delivery method is unexpected
  def redirect_to_sign_in_when_delivery_method_unexpected(method:, delivery_method:, token:)
    HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: "HawthorneCore::User::SessionController", method:, message: 'Unexpected delivery method', delivery_method:, token: })
    redirect_to sign_in_path
  end

  # redirect the user to the sign-in page when the user is not found with token
  def redirect_to_sign_in_when_user_not_found(method:, token:)
    HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: "HawthorneCore::User::SessionController", method:, message: "User not found with token", token: })
    redirect_to sign_in_path
  end

  # ------------------------

  # render an error message that the code is inactive
  def render_code_inactive_error(user_site:, delivery_method:, keep_signed_in:)
    (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.sign_in_code_set?
    (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.sign_in_code_expired?
    (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.sign_in_code_max_failed_attempts_reached?
    HawthorneCore::UserAction::Log.sign_in_failure(user_id: user_site.user_id, failure_reason:, note: { sign_in_code: user_site.sign_in_code, sign_in_code_created_at: user_site.sign_in_code_created_at, sign_in_code_failed_attempts_count: user_site.sign_in_code_failed_attempts_count })
    user_site.refresh_sign_in_attrs_then_send_it(delivery_method:, keep_signed_in:)
    render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: })
  end

  # render an error message that the code does not match
  def render_code_not_match_error(user_site:, code:, delivery_method:, keep_signed_in:)
    HawthorneCore::UserAction::Log.sign_in_failure(user_id: user_site.user_id, failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { code:, code_to_match: user_site.sign_in_code })
    user_site.add_sign_in_code_failed_attempt
    if user_site.sign_in_code_max_failed_attempts_reached?
      user_site.refresh_sign_in_attrs_then_send_it(delivery_method:, keep_signed_in:)
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_max_failed_attempts_reached: true })
      return
    end
    render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match: true })
  end

  # render an error message that the email has a syntax error
  def render_email_syntax_error(email:)
    HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { email: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
  end

  # ------------------------

end