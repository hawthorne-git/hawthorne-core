# v3.0

module HawthorneCore::Errors
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # render an error message that the code is inactive
    def render_shared_code_inactive_error(action: nil, note:, is_code_set:, is_code_expired:, are_max_attempts_reached:, refresh_attrs_then_send_it:, user_id: nil, from_magic_link: false)
      (code_not_set = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_not_set) unless is_code_set.call
      (code_expired = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_expired) if is_code_expired.call
      (code_max_failed_attempts_reached = true; failure_reason = HawthorneCore::UserAction::FailureReason.code_max_failed_attempts_reached) if are_max_attempts_reached.call
      HawthorneCore::UserAction::Log.sign_in_failure(user_id:, failure_reason:, note:) if action == 'SIGN_IN'
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason:, note:) unless action == 'SIGN_IN'
      refresh_attrs_then_send_it.call
      if from_magic_link
        redirect_to verify_sign_in_code_path(token: HawthorneCore::User.find_token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_not_set:, code_expired:, code_max_failed_attempts_reached:)
      else
        render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_set:, code_expired:, code_max_failed_attempts_reached: })
      end
    end

    # ---------------------------------------------------------------------------

    # render an error message that the code does not match
    def render_shared_code_not_match_error(action:, code:, code_to_match:, add_failed_attempt:, are_max_attempts_reached:, refresh_attrs_then_send_it:, user_id: nil, from_magic_link: false)
      HawthorneCore::UserAction::Log.sign_in_failure(user_id:, failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { code:, code_to_match: code_to_match }) if action == 'SIGN_IN'
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.code_not_match, note: { action:, code:, code_to_match: }) unless action == 'SIGN_IN'
      add_failed_attempt.call
      if are_max_attempts_reached.call
        refresh_attrs_then_send_it.call
        if (action == 'SIGN_IN') && from_magic_link
          redirect_to verify_sign_in_code_path(token: HawthorneCore::User.find_token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_max_failed_attempts_reached: true)
        else
          render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_max_failed_attempts_reached: true })
        end
      else
        if (action == 'SIGN_IN') && from_magic_link
          redirect_to verify_sign_in_code_path(token: HawthorneCore::User.find_token(user_id:), delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, keep_signed_in: true, from_magic_link:, code_not_match: true)
        else
          render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/verify_code_failed', locals: { code_not_match: true })
        end
      end
    end

    # ---------------------------------------------------------------------------

  end

end