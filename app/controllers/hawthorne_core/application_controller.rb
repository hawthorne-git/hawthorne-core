# v3.0

class HawthorneCore::ApplicationController < ::ApplicationController

  include HawthorneCore::Cache,
          HawthorneCore::UserAuthentication,
          HawthorneCore::UserSessionIssuer

  # ---------------------------------------------------------------------------

  # only support 'modern' browsers
  allow_browser versions: :modern

  # ---------------------------------------------------------------------------

  # set an attribute, noting if the page is to be re-cached
  before_action :set_clear_cache_attr

  # set the sites header / footer versions in the cache
  before_action :set_site_header_footer_versions_in_cache

  # verify that the users session is captured in the database - if not previously verified
  before_action :verify_user_session, if: proc { !user_session_verified? }

  # create the users session - if it does not exist
  before_action :create_user_session, if: proc { !user_session? }

  # determine if the user is signed in
  before_action :signed_in?

  # ---------------------------------------------------------------------------

  # changes to the importmap will invalidate the etag for HTML responses - rails v8 default
  stale_when_importmap_changes

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

  private

  # for code ease, define the site id
  def site_id = HawthorneCore::Site.this_site_id

  # for code ease, define the user id
  def user_id = session[:user_id]

  # ----------------------

  # render an error message that the code is inactive
  def render_shared_code_inactive_error(action: nil, note:, is_code_set:, is_code_expired:, are_max_attempts_reached:, refresh_attrs_then_send_it:, user_id: nil, from_magic_link: false)
    (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless is_code_set.call
    (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if is_code_expired.call
    (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if are_max_attempts_reached.call
    HawthorneCore::UserAction::Log.sign_in_failure(user_id:, failure_reason:, note:) if action == 'SIGN_IN'
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason:, note:) unless action == 'SIGN_IN'
    refresh_attrs_then_send_it.call
    if from_magic_link
      redirect_to verify_sign_in_code_path(token: HawthorneCore::User.token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_not_set:, code_expired:, code_max_failed_attempts_reached:)
    else
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: })
    end
  end

  # render an error message that the code does not match
  def render_shared_code_not_match_error(action:, code:, code_to_match:, add_failed_attempt:, are_max_attempts_reached:, refresh_attrs_then_send_it:, user_id: nil, from_magic_link: false)
    HawthorneCore::UserAction::Log.sign_in_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { code:, code_to_match: code_to_match }) if action == 'SIGN_IN'
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action:, code:, code_to_match: }) unless action == 'SIGN_IN'
    add_failed_attempt.call
    if are_max_attempts_reached.call
      refresh_attrs_then_send_it.call
      if (action == 'SIGN_IN') && from_magic_link
        redirect_to verify_sign_in_code_path(token: HawthorneCore::User.token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_max_failed_attempts_reached: true)
      else
        render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_max_failed_attempts_reached: true })
      end
    else
      if (action == 'SIGN_IN') && from_magic_link
        redirect_to verify_sign_in_code_path(token: HawthorneCore::User.token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_not_match: true)
      else
        render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match: true })
      end
    end
  end

  # ---------------------------------------------------------------------------

end