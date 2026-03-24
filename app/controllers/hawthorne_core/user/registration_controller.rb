# v3.0XXX

class HawthorneCore::User::RegistrationController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  before_action :validate_signed_in?, only: [
  ]

  before_action :validate_signed_out?, only: [
    :sign_up_show,
    :sign_up,
  ]

  # -----------------------------------------------------------------------------

  # show the sign-up page
  def sign_up_show
    @html_title = 'Create Account'
    @meta_description = 'Create your Hawthorne account'
  end

  # -----------------------------------------------------------------------------

  # sign-up the site user
  def sign_up

    # ----------------------

    # get the page attributes
    email_address = params[:email_address].to_s.downcase.strip
    phone_number = params[:phone_nbr].to_s.downcase.strip

    # ----------------------

    # validate that the email address is not already taken
    # if invalid, log the failed attempt and return back to the sign-up page and display an error message
    if HawthorneCore::User.email_address_taken?(email_address)
      site_user = HawthorneCore::User.select(:site_user_id).find_by(email_address: email_address)
      @sign_up_failed = @email_address_failed = @email_address_taken = true
      @email_address = email_address
      #@only_sign_in_via_sso = user.only_sign_in_via_sso?(email_address)
      HawthorneCore::UserAction::Log.sign_up_failure(HawthorneCore::UserAction::FailureReason.email_taken, { site_user_id: site_user.id, email_address: email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('sign_up_failed_turbo_frame', partial: '/hawthorne_core/partials/user/sign_up_failed') and return
    end

    # ----------------------

    # validate that the email address does not have a syntax error
    # if invalid, log the failed attempt and return back to the sign-up page and display an error message
    if email_address_syntax_invalid?(email_address)
      @sign_up_failed = @email_address_failed = @email_address_syntax_error = true
      HawthorneCore::UserAction::Log.sign_up_failure(HawthorneCore::UserAction::FailureReason.email_syntax_error, { email_address: email_address }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('sign_up_failed_turbo_frame', partial: '/hawthorne_core/partials/user/sign_up_failed') and return
    end

    # ----------------------

    # validate that the phone number
    # if invalid, log the failed attempt and return back to the sign-up page and display an error message
    if phone_number_invalid?(phone_number)
      @sign_up_failed = @phone_number_failed = true
      HawthorneCore::UserAction::Log.sign_up_failure(HawthorneCore::UserAction::FailureReason.phone_number_syntax_error, { email_address: email_address, phone_number: phone_number }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('sign_up_failed_turbo_frame', partial: '/hawthorne_core/partials/user/sign_up_failed') and return
    end

    # ----------------------

    # we have a successful account sign-up

    # create the site user record
    token = HawthorneCore::User.create_record(email_address, phone_number, request.remote_ip, cookies[:user_session_token])

    # if there was an unexpected error creating the site user record
    # return back to the sign-up page and display an error message (note that the exception is logged within create record method)
    unless token.present?
      @sign_up_failed = @create_site_user_record_failed = true
      render turbo_stream: turbo_stream.update('sign_up_failed_turbo_frame', partial: '/hawthorne_core/partials/user/sign_up_failed') and return
    end

    redirect_to validate_email_path(token: token)

    # ----------------------

  end

  # -----------------------------------------------------------------------------

  # validate a users email address via a magic link
  def validate_email_via_magic_link

    # ----------------------

    # get the page attributes
    token = params[:token]
    pin = params[:pin]

    # ----------------------

    # find the site user via their token (small web id)
    site_user = HawthorneCore::User.
      select(:site_user_id, :email_address, :pin, :pin_created_at).
      find_by(small_web_id: token)

    # ----------------------

    # if the site user is NOT found via their token
    # log the failed attempt, and redirect the user to a failure page
    unless site_user
      HawthorneCore::UserAction::Log.validate_email_address_via_magic_link_failure(nil, HawthorneCore::UserAction::FailureReason.site_user_not_found, { token: token }, request.remote_ip, cookies[:user_session_token])
      redirect_to validate_email_via_magic_link_failure_path and return
    end

    # if the pin has too many failed validation attempts
    # log the failed attempt, and redirect the user to a failure page
    # TODO ...

    # if the pin is not active
    # log the failed attempt, and redirect the user to a failure page
    unless site_user.pin_active?
      HawthorneCore::UserAction::Log.validate_email_address_via_magic_link_failure(site_user.id, HawthorneCore::UserAction::FailureReason.pin_expired, { pin: site_user.pin }, request.remote_ip, cookies[:user_session_token])
      redirect_to validate_email_via_magic_link_failure_path(email_address: site_user.email_address) and return

    end

    # if the pin does not match
    # log the failed attempt, and redirect the user to a failure page
    unless site_user.pin_match?(pin)
      HawthorneCore::UserAction::Log.validate_email_address_via_magic_link_failure(site_user.id, HawthorneCore::UserAction::FailureReason.pin_not_match, { pin: site_user.pin, pin_to_match: pin }, request.remote_ip, cookies[:user_session_token])
      redirect_to validate_email_via_magic_link_failure_path(email_address: site_user.email_address) and return
    end

    # ----------------------

    puts 'VALIDATE EMAIL ADDRESS'

  end

  # -----------------------------------------------------------------------------

  # show the page stating that there was a failure - the magic link did not work
  def validate_email_via_magic_link_failure_show
    @page_from = 'magic-link-email'
    @email_address = params[:email_address].to_s.downcase.strip
    @html_title = 'Validate Email via Magic Link Failed'
  end

  # -----------------------------------------------------------------------------

end