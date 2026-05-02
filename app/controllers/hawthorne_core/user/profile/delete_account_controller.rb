# v3.0

class HawthorneCore::User::Profile::DeleteAccountController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  # show the page for the user to start the process, to delete their account
  def show

    # clear the users delete account attributes
    HawthorneCore::User.clear_delete_account_attrs(user_id:)

    # ----------------------

    @html_title = 'Delete Account | Profile'

  end

  # -----------------------------------------------------------------------------

  # verify that the user wants to delete their account
  def verify

    # set the users delete account attributes
    HawthorneCore::User.set_delete_account_attrs_then_send_it(user_id:)

    # ----------------------

    # redirect the user to verify their code, sent via email
    redirect_to account_profile_delete_account_verify_code_path

  end

  # -----------------------------------------------------------------------------

  # show the page for the user to verify their code, to update their phone number
  def verify_code_show

    # find the users email
    @email = HawthorneCore::User.email(user_id:)

    # ----------------------

    @html_title = 'Delete Account | Profile'

  end

  # -----------------------------------------------------------------------------

  # resend the user their code, to delete their account
  # as the show action sends the user their code - no need to here
  def resend_code
    HawthorneCore::Email::SendDeleteAccountCodeJob.perform_later(user_id:)
    redirect_to account_profile_delete_account_verify_code_path
  end

  # -----------------------------------------------------------------------------

  # verify the users code, to update their email
  def verify_code

    code = params[:code]

    # ----------------------

    # find the users site record ... the new delete account attributes are specific to each site
    user_site = HawthorneCore::UserSite.find_by(user_id:, site_id:)

    # ----------------------

    # verify that the code is active, and matches
    return render_code_inactive_error(user_site:) unless user_site.delete_account_code_active?
    return render_code_not_match_error(user_site:, code:) unless user_site.delete_account_code_match?(code:)

    # ----------------------

    # the code is verified!

    # delete the users account
    HawthorneCore::User.delete_account(user_id:)

    # reset the session, which also logs the user out
    reset_session

    # ----------------------

    # redirect the user to a message noting that their account is deleted
    redirect_to account_deleted_path

  end

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  private

  # render an error message that the code is inactive
  def render_code_inactive_error(user_site:)
    render_shared_code_inactive_error(
      note: { delete_account_code: user_site.delete_account_code, delete_account_code_created_at: user_site.delete_account_code_created_at, delete_account_code_failed_attempts_count: user_site.delete_account_code_failed_attempts_count },
      is_code_set: -> { user_site.delete_account_code_set? },
      is_code_expired: -> { user_site.delete_account_code_expired? },
      are_max_attempts_reached: -> { user_site.delete_account_code_max_failed_attempts_reached? },
      refresh_attrs_then_send_it: -> { user_site.refresh_delete_account_attrs_then_send_it }
    )
  end

  # render an error message that the code does not match
  def render_code_not_match_error(user_site:, code:)
    render_shared_code_not_match_error(
      action: 'DELETE_ACCOUNT',
      code:,
      code_to_match: user_site.delete_account_code,
      add_failed_attempt: -> { user_site.add_delete_account_code_failed_attempt },
      are_max_attempts_reached: -> { user_site.delete_account_code_max_failed_attempts_reached? },
      refresh_attrs_then_send_it: -> { user_site.refresh_delete_account_attrs_then_send_it }
    )
  end

  # -----------------------------------------------------------------------------

end