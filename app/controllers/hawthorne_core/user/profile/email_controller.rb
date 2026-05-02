# v3.0

class HawthorneCore::User::Profile::EmailController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their email
  def show

    # ----------------------

    # find the users email
    @email = HawthorneCore::User.where(user_id:).pick(:email)

    # clear the users new email attributes
    HawthorneCore::User.clear_new_email_attrs(user_id:)

    # ----------------------

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify the users email, to update
  def verify

    email = params[:email].to_s.strip.downcase

    # ----------------------

    # verify that the email does not have a syntax error, does not match the current email, and is not taken
    return render_email_syntax_error(email:) unless HawthorneCore::Helpers::Email.syntax_valid?(email:)
    return render_email_identical_error(email:) if email == HawthorneCore::User.email(user_id:)
    return render_email_taken_error(email:) if HawthorneCore::Helpers::Email.taken?(email:)

    # ----------------------

    # the email is valid!

    # set the users new email attributes, then send the user an email with a code to verify their email
    HawthorneCore::User.set_new_email_attrs_then_send_it(user_id:, email:)

    # ----------------------

    # redirect the user to verify their code, sent via email
    redirect_to account_profile_verify_email_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update the email
  def verify_code_show

    # find the users new email
    @new_email = HawthorneCore::UserSite.where(user_id:, site_id:).pick(:new_email)

    # ----------------------

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to update their email
  def resend_code
    HawthorneCore::Email::SendEmailUpdateCodeJob.perform_later(user_id:)
    redirect_to account_profile_verify_email_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their email
  def verify_code

    code = params[:code]

    # ----------------------

    # find the users site record ... the new email attributes are specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # ----------------------

    # verify that the code is active, and matches
    return render_code_inactive_error(user_site:) unless user_site.new_email_code_active?
    return render_code_not_match_error(user_site:, code:) unless user_site.new_email_code_match?(code:)

    # ----------------------

    # the code is verified!

    # update the users email
    HawthorneCore::User.update_email(user_id:, email: user_site.new_email)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  private

  # render an error message that the code is inactive
  def render_code_inactive_error(user_site:)
    (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.new_email_code_set?
    (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.new_email_code_expired?
    (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.new_email_code_max_failed_attempts_reached?
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason:, note: { new_email_code: user_site.new_email_code, new_email_code_created_at: user_site.new_email_code_created_at, new_email_code_failed_attempts_count: user_site.new_email_code_failed_attempts_count })
    user_site.refresh_new_email_attrs_then_send_it
    render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: })
  end

  # render an error message that the code does not match
  def render_code_not_match_error(user_site:, code:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action: 'UPDATE_EMAIL', code:, code_to_match: user_site.new_email_code })
    user_site.add_new_email_code_failed_attempt
    if user_site.new_email_code_max_failed_attempts_reached?
      user_site.refresh_new_email_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_max_failed_attempts_reached: true })
    else
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match: true })
    end
  end

  # render an error message that the new email is identical to the current email
  def render_email_identical_error(email:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_identical, note: { email: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true })
  end

  # render an error message that the email has a syntax error
  def render_email_syntax_error(email:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { email: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
  end

  # render an error message that the email is taken
  def render_email_taken_error(email:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_taken, note: { email: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { taken: true })
  end

  # -----------------------------------------------------------------------------

end