# v3.0

class HawthorneCore::User::Profile::PhoneNumberController < HawthorneCore::AccountApplicationController

  # ----------------------------------------------------------------------------- 

  # show the page for the user to update their phone number
  def show

    # find the users phone number
    @phone_number = HawthorneCore::User.phone_number(user_id:)

    # clear the users new phone number attributes
    HawthorneCore::User.clear_new_phone_number_attrs(user_id:)

    # ----------------------

    @html_title = "#{@phone_number.blank? ? 'Add' : 'Update'} Phone Number | Profile"

  end

  # -----------------------------------------------------------------------------

  # verify the users phone number
  def verify

    phone_number = params[:new_phone_number].to_s.squish

    # ----------------------

    # verify that the phone number does not have a syntax error, and does not match the current phone number
    return render_phone_number_syntax_error(phone_number:) unless HawthorneCore::Helpers::PhoneNumber.us_syntax_valid?(phone_number:)
    return render_phone_number_identical_error(phone_number:) if HawthorneCore::Helpers::PhoneNumber.match?(phone_number:, phone_number_to_match: HawthorneCore::User.phone_number(user_id:))

    # ----------------------

    # the new phone number is valid!

    # set the users new phone number attributes
    # then send the user a text message with a code to verify their new phone number
    HawthorneCore::User.set_new_phone_number_attrs_then_send_it(user_id:, phone_number:)

    # ----------------------

    # redirect the user to verify their code, sent via text message
    redirect_to account_profile_verify_phone_number_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update their phone number
  def verify_code_show

    # find the users current and new phone number
    @current_phone_number = HawthorneCore::User.phone_number(user_id:)
    @new_phone_number = HawthorneCore::UserSite.new_phone_number(user_id:)

    # ----------------------

    @html_title = "#{@current_phone_number.blank? ? 'Add' : 'Update'} Phone Number | Profile"

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to update their phone number
  def resend_code
    HawthorneCore::Text::SendPhoneNumberUpdateCodeJob.perform_later(user_id:)
    redirect_to account_profile_verify_phone_number_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their phone number
  def verify_code

    code = params[:code]

    # ----------------------

    # find the users site record ... the new phone number attributes are specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # ----------------------

    # verify that the code is active, and matches
    return render_code_inactive_error(user_site:) unless user_site.new_phone_number_code_active?
    return render_code_not_match_error(user_site:, code:) unless user_site.new_phone_number_code_match?(code:)

    # ----------------------

    # the code is verified!

    # update the users phone number
    HawthorneCore::User.update_phone_number(user_id:, phone_number: user_site.new_phone_number)

    # ----------------------

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

  # delete the users phone number
  def delete

    # remove the users phone number
    HawthorneCore::User.remove_phone_number(user_id:)

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
    render_shared_code_inactive_error(
      note: { new_phone_number_code: user_site.new_phone_number_code, new_phone_number_code_created_at: user_site.new_phone_number_code_created_at, new_phone_number_code_failed_attempts_count: user_site.new_phone_number_code_failed_attempts_count },
      is_code_set: -> { user_site.new_phone_number_code_set? },
      is_code_expired: -> { user_site.new_phone_number_code_expired? },
      are_max_attempts_reached: -> { user_site.new_phone_number_code_max_failed_attempts_reached? },
      refresh_attrs_then_send_it: -> { user_site.refresh_new_phone_number_attrs_then_send_it }
    )
  end

  # render an error message that the code does not match
  def render_code_not_match_error(user_site:, code:)
    render_shared_code_not_match_error(
      action: 'UPDATE_PHONE_NUMBER',
      code:,
      code_to_match: user_site.new_phone_number_code,
      add_failed_attempt: -> { user_site.add_new_phone_number_code_failed_attempt },
      are_max_attempts_reached: -> { user_site.new_phone_number_code_max_failed_attempts_reached? },
      refresh_attrs_then_send_it: -> { user_site.refresh_new_phone_number_attrs_then_send_it }
    )
  end

  # render an error message that the new phone number is identical to the current phone number
  def render_phone_number_identical_error(phone_number:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_identical, note: { phone_number: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true })
  end

  # render an error message that the phone number has a syntax error
  def render_phone_number_syntax_error(phone_number:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_syntax_error, note: { phone_number: })
    render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
  end

end