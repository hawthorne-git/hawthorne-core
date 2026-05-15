class HawthorneCore::User::SessionController < HawthorneCore::ApplicationController

  include HawthorneCore::Validation::Code,
          HawthorneCore::Validation::Session

  # -----------------------------------------------------------------------------

  # verify that the user is signed out prior to all action, except signing out
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

    # verify that the email does not have a syntax error
    return render_email_syntax_error(email:) unless HawthorneCore::Helpers::Email.syntax_valid?(email:)

    # find (or create) the user
    # set the users sign-in attributes
    user = HawthorneCore::User.find_or_create(email:)
    user.set_sign_in_attrs

    # send the user their code via default delivery method, email or text
    send_sign_in_code(user_id: user.id, keep_signed_in:, delivery_method: user.sign_in_code_default_delivery)

    # redirect the user to verify their sign-in code
    redirect_to verify_sign_in_code_path(token: user.token, delivery_method: user.sign_in_code_default_delivery, keep_signed_in:)

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their sign-in code
  def verify_code_show

    @token = token = params[:token]
    @delivery_method = delivery_method = params[:delivery_method]
    @keep_signed_in = params[:keep_signed_in].to_i

    # in the unexpected case where the user is not found or the code delivery method is an unexpected value, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'verify_sign_in_code', token:) unless HawthorneCore::User.token_exists?(token:)
    return redirect_to_sign_in_when_delivery_method_unexpected(method: 'verify_sign_in_code', delivery_method:, token:) unless HawthorneCore::User::sign_in_code_delivery_methods.include?(delivery_method)

    # find the users email and phone number
    @email, @phone_number = HawthorneCore::User.active.where(token:).pick(:email, :phone_number)

    @html_title = 'Verify Sign-In Code'

  end

  # -----------------------------------------------------------------------------

  # resend the user their sign-in code via delivery method
  def resend_code

    token = params[:token]
    delivery_method = params[:delivery_method]
    keep_signed_in = params[:keep_signed_in]

    # in the unexpected case where the user is not found or the code delivery method is an unexpected value, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'verify_sign_in_code', token:) unless HawthorneCore::User.token_exists?(token:)
    return redirect_to_sign_in_when_delivery_method_unexpected(method: 'verify_sign_in_code', delivery_method:, token:) unless HawthorneCore::User::sign_in_code_delivery_methods.include?(delivery_method)

    # find the user id by their token
    user_id = HawthorneCore::User.user_id_by_token(token:)

    # send the user their code via prior delivery method, email or text
    send_sign_in_code(user_id:, keep_signed_in:, delivery_method:)

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
    from_magic_link = params[:from_magic_link]
    delivery_method = from_magic_link.present? ? HawthorneCore::User::CODE_VIA_EMAIL : params[:delivery_method]
    keep_signed_in = params[:keep_signed_in].to_i

    # in the unexpected case where the user is not found or the code delivery method is an unexpected value, return back to the sign-in page
    return redirect_to_sign_in_when_user_not_found(method: 'verify_sign_in_code', token:) unless HawthorneCore::User.token_exists?(token:)
    return redirect_to_sign_in_when_delivery_method_unexpected(method: 'verify_sign_in_code', delivery_method:, token:) unless HawthorneCore::User::sign_in_code_delivery_methods.include?(delivery_method)

    # find the user id by their token
    user_id = HawthorneCore::User.user_id_by_token(token:)

    # find the users site record ... the sign-in code is specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # verify that the code is active, and matches
    return render_sign_in_code_inactive_error(user_site:, delivery_method:, keep_signed_in:, from_magic_link:) unless user_site.sign_in_code_active?
    return render_sign_in_code_not_match_error(user_site:, code:, delivery_method:, keep_signed_in:, from_magic_link:) unless user_site.sign_in_code_match?(code:)

    # the code is verified

    # sign-in the user
    HawthorneCore::User.sign_in(user_id:, user_session_token: cookies[:user_session_token], keep_signed_in:)

    # set the user into the session
    session[:user_id] = user_id

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  # sign-out the user
  def sign_out

    # sign-out the user
    HawthorneCore::User.sign_out(user_id:)

    # reset the session
    reset_session

    # redirect the user to the sites home page
    redirect_to('/')

  end

  # -----------------------------------------------------------------------------

  private

  # send the user their sign-in code, via delivery method
  def send_sign_in_code(user_id:, keep_signed_in:, delivery_method:)
    HawthorneCore::Email::SendSignInCodeJob.perform_later(user_id:, keep_signed_in:) if delivery_method == HawthorneCore::User::CODE_VIA_EMAIL
    HawthorneCore::Text::SendSignInCodeJob.perform_later(user_id:) if delivery_method == HawthorneCore::User::CODE_VIA_PHONE
  end


  # -----------------------------------------------------------------------------

end