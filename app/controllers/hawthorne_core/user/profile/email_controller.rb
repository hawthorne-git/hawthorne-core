# v3.0

class HawthorneCore::User::Profile::EmailController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to update their email
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # clear the users new email attributes
    @user.clear_new_email_attrs

    # ----------------------

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify the users email, to update
  def verify

    # get the request attributes
    new_email = params[:new_email].to_s.downcase.strip

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email).
      active.
      find_by(user_id: session[:user_id])

    # ----------------------

    # verify that the new email does not have a syntax error
    unless HawthorneCore::Helpers::Email.syntax_valid?(email: new_email)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { new_email: new_email })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_failed', locals: { syntax_error: true }) and return
    end

    # verify that the new email does not match the current email
    if user.email == new_email
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_identical, note: { current_email: user.email, new_email: new_email })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_failed', locals: { identical: true }) and return
    end

    # verify that the new email is not taken
    if HawthorneCore::Helpers::Email.taken?(email: new_email)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_taken, note: { new_email: new_email })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'new_email_failed', locals: { taken: true }) and return
    end

    # ----------------------

    # the new email is valid!

    # set the users new email attributes
    user.set_new_email_attrs(new_email:)

    # send the user an email with a code to verify their new email
    HawthorneCore::Email::SendEmailUpdateCodeJob.perform_later(user_id: user.id)

    # ----------------------

    redirect_to account_profile_verify_email_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update the email
  def verify_code_show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :email, :full_name).
      active.
      find_by(user_id: session[:user_id])

    # find the users new email
    @new_email = HawthorneCore::UserSite.where(user_id: @user.id, site_id: HawthorneCore::Site.this_site_id).pick(:new_email)

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

    # get the request attributes
    code = params[:code]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :email).
      active.
      find_by(user_id: session[:user_id])

    # find the users site record ... the new email attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_email, :new_email_code, :new_email_code_created_at, :new_email_code_failed_attempts_count).
      find_by(user_id: user.id, site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the code is inactive ...
    # refresh the code, resend, then return back and display an error message
    unless user_site.new_email_code_active?
      (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.new_email_code_set?
      (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.new_email_code_expired?
      (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.new_email_code_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, failure_reason, { new_email_code: user_site.new_email_code, new_email_code_created_at: user_site.new_email_code_created_at, new_email_code_failed_attempts_count: user_site.new_email_code_failed_attempts_count })
      user_site.refresh_new_email_code_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { not_set: code_not_set, expired: code_expired, max_failed_attempts_reached: code_max_failed_attempts_reached }) and return
    end

    # verify the code - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered code does not match - log it, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users code, resend
    # lastly, when the entered code does not match, return back and display an error message
    unless user_site.new_email_code_match?(code)
      HawthorneCore::UserAction::Log.update_profile_email_failure(user.id, HawthorneCore::UserAction::FailureReason.code_not_match, { entered_code: code, code_to_match: user_site.new_email_code })
      user_site.add_new_email_code_failed_attempt
      if user_site.new_email_code_max_failed_attempts_reached?
        code_max_failed_attempts_reached = true
        user_site.refresh_new_email_code_then_send_it
      else
        code_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { not_match: code_not_match, max_failed_attempts_reached: code_max_failed_attempts_reached }) and return
    end

    # ----------------------

    # the code is verified!

    # temporarily capture the old and new values, for logging
    old_email = user.email
    new_email = user_site.new_email

    # update the users email,
    # then clear the users update email attributes
    user.update_columns(email: new_email)
    user_site.clear_new_email_attrs

    # log it
    HawthorneCore::UserAction::Log.update_profile(note: { old_email: old_email, new_email: new_email })

    # update the users email, within stripe
    HawthorneCore::Stripe::UpdateCustomerEmailJob.perform_later(user.id)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end