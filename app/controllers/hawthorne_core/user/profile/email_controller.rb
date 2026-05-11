# v3.0

class HawthorneCore::User::Profile::EmailController < HawthorneCore::AccountApplicationController

  include HawthorneCore::Validation::Code,
          HawthorneCore::Validation::Email

  # -----------------------------------------------------------------------------

  # show the page for the user to update their email
  def show

    # find the users email
    @email = HawthorneCore::User.email(user_id:)

    # clear the users new email attributes
    HawthorneCore::User.clear_new_email_attrs(user_id:)

    @html_title = 'Update Email | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify the users email, to update
  def verify

    email = params[:email].to_s.strip.downcase

    # verify that the email does not have a syntax error, does not match the current email, and is not taken
    return render_email_syntax_error(email:) unless HawthorneCore::Helpers::Email.syntax_valid?(email:)
    return render_email_identical_error(email:) if email == HawthorneCore::User.email(user_id:)
    return render_email_taken_error(email:) if HawthorneCore::Helpers::Email.taken?(email:)

    # the email is valid!

    # set the users new email attributes, then send the user an email with a code to verify their email
    HawthorneCore::User.set_new_email_attrs_then_send_it(user_id:, email:)

    # redirect the user to verify their code, sent via email
    redirect_to account_profile_verify_email_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update the email
  def verify_code_show

    # find the users new email
    @new_email = HawthorneCore::UserSite.new_email(user_id:)

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

    # find the users site record ... the new email attributes are specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # verify that the code is active, and matches
    return render_email_code_inactive_error(user_site:) unless user_site.new_email_code_active?
    return render_email_code_not_match_error(user_site:, code:) unless user_site.new_email_code_match?(code:)

    # the code is verified!

    # update the users email
    HawthorneCore::User.update_email(user_id:, email: user_site.new_email)

    # redirect the user to view their profile
    redirect_to account_profile_path

  end

  # -----------------------------------------------------------------------------

end