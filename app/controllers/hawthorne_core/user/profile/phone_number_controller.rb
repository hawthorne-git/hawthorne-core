class HawthorneCore::User::Profile::PhoneNumberController < HawthorneCore::AccountApplicationController

  include HawthorneCore::Validation::Code,
          HawthorneCore::Validation::PhoneNumber

  # ----------------------------------------------------------------------------- 

  # show the page for the user to update their phone number
  def show

    # find the users phone number
    @phone_number = HawthorneCore::User.phone_number(user_id:)

    # clear the users new phone number attributes
    HawthorneCore::User.clear_new_phone_number_attrs(user_id:)

    @html_title = "#{@phone_number.blank? ? 'Add' : 'Update'} Phone Number | Profile"

  end

  # -----------------------------------------------------------------------------

  # verify the users phone number
  def verify

    phone_number = params[:new_phone_number].to_s.squish

    # verify that the phone number does not have a syntax error, and does not match the current phone number
    return render_phone_number_syntax_error(phone_number:) unless HawthorneCore::Helpers::PhoneNumber.us_syntax_valid?(phone_number:)
    return render_phone_number_identical_error(phone_number:) if HawthorneCore::Helpers::PhoneNumber.match?(phone_number:, phone_number_to_match: HawthorneCore::User.phone_number(user_id:))

    # the new phone number is valid!

    # set the users new phone number attributes
    # then send the user a text message with a code to verify their new phone number
    HawthorneCore::User.set_new_phone_number_attrs_then_send_it(user_id:, phone_number:)

    # redirect the user to verify their code, sent via text message
    redirect_to account_profile_verify_phone_number_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update their phone number
  def verify_code_show

    # find the users current and new phone number
    @current_phone_number = HawthorneCore::User.phone_number(user_id:)
    @new_phone_number = HawthorneCore::UserSite.new_phone_number(user_id:)

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

    # find the users site record ... the new phone number attributes are specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # verify that the code is active, and matches
    return render_phone_number_code_inactive_error(user_site:) unless user_site.new_phone_number_code_active?
    return render_phone_number_code_not_match_error(user_site:, code:) unless user_site.new_phone_number_code_match?(code:)

    # the code is verified!

    # update the users phone number
    HawthorneCore::User.update_phone_number(user_id:, phone_number: user_site.new_phone_number)

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

  # delete the users phone number
  def delete

    # remove the users phone number
    HawthorneCore::User.remove_phone_number(user_id:)

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end