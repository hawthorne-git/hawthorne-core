# v3.0

class HawthorneCore::User::Profile::PhoneNumberController < HawthorneCore::AccountApplicationController

  # ----------------------------------------------------------------------------- 

  # show the page for the user to update their phone number
  def show

    # find the users phone number
    @phone_number = HawthorneCore::User.
      where(user_id: session[:user_id]).
      pick(:phone_number)

    # clear the users new phone number attributes
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      clear_new_phone_number_attrs

    # ----------------------

    @html_title = "#{@phone_number.blank? ? 'Add' : 'Update'} Phone Number | Profile"

  end

  # -----------------------------------------------------------------------------

  # verify the users phone number
  def verify

    phone_number = params[:new_phone_number].to_s.squish

    # ----------------------

    # verify that the phone number does not have a syntax error
    unless HawthorneCore::Helpers::PhoneNumber.us_syntax_valid?(phone_number:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_syntax_error, note: { phone_number: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true }) and return
    end

    # verify that the phone number does not match the current phone number
    if HawthorneCore::Helpers::PhoneNumber.match?(phone_number:, phone_number_to_match: HawthorneCore::User.where(user_id: session[:user_id]).pick(:phone_number))
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_identical, note: { phone_number: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true }) and return
    end

    # ----------------------

    # the new phone number is valid!

    # set the users new phone number attributes
    HawthorneCore::User.
      select(:user_id).
      find_by(user_id: session[:user_id]).
      set_new_phone_number_attrs(phone_number:)

    # send the user a text message with a code to verify their new phone number
    HawthorneCore::Text::SendPhoneNumberUpdateCodeJob.perform_later(user_id: session[:user_id])

    # ----------------------

    # redirect the user to verify their code, sent via text message
    redirect_to account_profile_verify_phone_number_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update their phone number
  def verify_code_show

    # find the users current phone number
    @current_phone_number = HawthorneCore::User.
      where(user_id: session[:user_id]).
      pick(:phone_number)

    # find the users new phone number
    @new_phone_number = HawthorneCore::UserSite.
      where(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id).
      pick(:new_phone_number)

    # ----------------------

    @html_title = "#{@current_phone_number.blank? ? 'Add' : 'Update'} Phone Number | Profile"

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to update their phone number
  def resend_code
    HawthorneCore::Text::SendPhoneNumberUpdateCodeJob.perform_later(user_id: session[:user_id])
    redirect_to account_profile_verify_phone_number_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their phone number
  def verify_code

    code = params[:code]

    # ----------------------

    # find the users site record ... the new phone number attributes are specific to each site
    user_site = HawthorneCore::UserSite.
      select(:user_site_id, :user_id, :new_phone_number, :new_phone_number_code, :new_phone_number_code_created_at, :new_phone_number_code_failed_attempts_count).
      find_by(user_id: session[:user_id], site_id: HawthorneCore::Site.this_site_id)

    # ----------------------

    # if the code is inactive ...
    # refresh the code, resend, then return back and display an error message
    unless user_site.new_phone_number_code_active?
      (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless user_site.new_phone_number_code_set?
      (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if user_site.new_phone_number_code_expired?
      (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if user_site.new_phone_number_code_max_failed_attempts_reached?
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: failure_reason, note: { new_phone_number_code: user_site.new_phone_number_code, new_phone_number_code_created_at: user_site.new_phone_number_code_created_at, new_phone_number_code_failed_attempts_count: user_site.new_phone_number_code_failed_attempts_count })
      user_site.refresh_new_phone_number_attrs_then_send_it
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: }) and return
    end

    # verify the code - it is set, not expired, and has not reached the max number of failed attempts
    # if the entered code does not match, increment the number of failed attempts
    # if the max number of failed attempts reached ... refresh the users code, resend
    # lastly, when the entered code does not match, return back and display an error message
    unless user_site.new_phone_number_code_match?(code:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action: 'UPDAATE_PHONE_NUMBER', code:, code_to_match: user_site.new_phone_number_code })
      user_site.add_new_phone_number_code_failed_attempt
      if user_site.new_phone_number_code_max_failed_attempts_reached?
        code_max_failed_attempts_reached = true
        user_site.refresh_new_phone_number_attrs_then_send_it
      else
        code_not_match = true
      end
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match:, code_max_failed_attempts_reached: }) and return
    end

    # ----------------------

    # the code is verified!

    # update the users phone number
    HawthorneCore::User.
      select(:user_id, :phone_number, :sign_in_code_default_delivery).
      find_by(user_id: session[:user_id]).
      update_phone_number(phone_number: user_site.new_phone_number)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

  # delete the users phone number
  def delete

    # remove the users phone number
    HawthorneCore::User.
      select(:user_id, :phone_number, :sign_in_code_default_delivery).
      find_by(user_id: session[:user_id]).
      remove_phone_number

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end