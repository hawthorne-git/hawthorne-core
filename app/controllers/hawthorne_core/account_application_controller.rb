# v3.0

class HawthorneCore::AccountApplicationController < ::HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in
  before_action :user_signed_in?

  # verify that the signed-in user exists as an active user
  before_action :active_user?

  # set the request context - the users id, ip, and session token
  before_action :set_request_context

  # ----------------------

  # clear the request context - the users id, ip, and session token
  after_action :clear_request_context

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

  private

  # render an error message that the code is inactive
  def render_shared_code_inactive_error(note:, is_code_set:, is_code_expired:, are_max_attempts_reached:, refresh_attrs_then_send_it:)
    (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless is_code_set.call
    (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if is_code_expired.call
    (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if are_max_attempts_reached.call
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason:, note:)
    refresh_attrs_then_send_it.call
    render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: })
  end

  # render an error message that the code does not match
  def render_shared_code_not_match_error(action:, code:, code_to_match:, add_failed_attempt:, are_max_attempts_reached:, refresh_attrs_then_send_it:)
    HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action:, code:, code_to_match: })
    add_failed_attempt.call
    if are_max_attempts_reached.call
      refresh_attrs_then_send_it.call
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_max_failed_attempts_reached: true })
    else
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match: true })
    end
  end

  # ---------------------------------------------------------------------------


end