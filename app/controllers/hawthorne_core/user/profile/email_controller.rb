# v3.0

class HawthorneCore::User::Profile::EmailController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their email
  def show

    # find the users email
    @email = HawthorneCore::User.
      where(user_id: session[:user_id]).
      pick(:email)

    # clear the users new email attributes
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      clear_new_email_attrs

    # ----------------------

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify the users email, to update
  def verify

    email = params[:email].to_s.strip.downcase

    # ----------------------

    # verify that the email does not have a syntax error
    unless HawthorneCore::Helpers::Email.syntax_valid?(email:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true }) and return
    end

    # verify that the email does not match the current email
    if email == HawthorneCore::User.where(user_id: session[:user_id]).pick(:email)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_identical, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true }) and return
    end

    # verify that the email is not taken
    if HawthorneCore::Helpers::Email.taken?(email:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_taken, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { taken: true }) and return
    end

    # ----------------------

    # the email is valid!

    # set the users new email attributes
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      set_new_email_attrs(email:)

    # send the user an email with a code to verify their email
    HawthorneCore::Email::SendEmailUpdateCodeJob.perform_later(user_id: session[:user_id])

    # ----------------------

    # redirect the user to verify their code, sent via email
    redirect_to account_profile_verify_email_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update the email
  def verify_code_show

    # find the users new email
    @new_email = HawthorneCore::UserSite.
      where(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).
      pick(:new_email)

    # ----------------------

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to update their email
  def resend_code
    HawthorneCore::Email::SendEmailUpdateCodeJob.perform_later(user_id: session[:user_id])
    redirect_to account_profile_verify_email_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their email
  def verify_code

    code = params[:code]

    # ----------------------

    # find the users site record ... the new email attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email, :new_email_code, :new_email_code_created_at, :new_email_code_failed_attempts_count).
      find_by(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the code is inactive ...
    # refresh the code, resend, then return back and display an error message
    unless user_site.new_email_code_active?
      (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.new_email_code_set?
      (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.new_email_code_expired?
      (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.new_email_code_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason:, note: { new_email_code: user_site.new_email_code, new_email_code_created_at: user_site.new_email_code_created_at, new_email_code_failed_attempts_count: user_site.new_email_code_failed_attempts_count })
      user_site.refresh_new_email_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: }) and return
    end

    # verify the code - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered code does not match, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users code, resend
    # lastly, when the entered code does not match, return back and display an error message
    unless user_site.new_email_code_match?(code:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action: 'UPDATE_EMAIL', code:, code_to_match: user_site.new_email_code })
      user_site.add_new_email_code_failed_attempt
      if user_site.new_email_code_max_failed_attempts_reached?
        code_max_failed_attempts_reached = true
        user_site.refresh_new_email_attrs_then_send_it
      else
        code_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match:, code_max_failed_attempts_reached: }) and return
    end

    # ----------------------

    # the code is verified!

    # update the users email
    HawthorneCore::User.
      select(:user_id, :email).
      find_by(user_id: session[:user_id]).
      update_email(email: user_site.new_email)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end