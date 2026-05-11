# v3.0

module HawthorneCore::Validation::Session
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # redirect the user to the sign-in page when the delivery method is unexpected
    def redirect_to_sign_in_when_delivery_method_unexpected(method:, delivery_method:, token:)
      HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: 'HawthorneCore::User::SessionController', method:, message: 'Unexpected delivery method', delivery_method:, token: })
      redirect_to sign_in_path
    end

    # ---------------------------------------------------------------------------

    # redirect the user to the sign-in page when the user is not found with token
    def redirect_to_sign_in_when_user_not_found(method:, token:)
      HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: 'HawthorneCore::User::SessionController', method:, message: 'User not found with token', token: })
      redirect_to sign_in_path
    end

    # ---------------------------------------------------------------------------

    # render an error message that the code is inactive
    def render_sign_in_code_inactive_error(user_site:, delivery_method:, keep_signed_in:, from_magic_link:)
      render_code_inactive_error(
        user_id: user_site.user_id,
        action: 'SIGN_IN',
        from_magic_link:,
        note: { sign_in_code: user_site.sign_in_code, sign_in_code_created_at: user_site.sign_in_code_created_at, sign_in_code_failed_attempts_count: user_site.sign_in_code_failed_attempts_count },
        is_code_set: -> { user_site.sign_in_code_set? },
        is_code_expired: -> { user_site.sign_in_code_expired? },
        are_max_attempts_reached: -> { user_site.sign_in_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_sign_in_attrs_then_send_it(delivery_method:, keep_signed_in:) }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the code does not match
    def render_sign_in_code_not_match_error(user_site:, code:, delivery_method:, keep_signed_in:, from_magic_link:)
      render_code_not_match_error(
        user_id: user_site.user_id,
        action: 'SIGN_IN',
        from_magic_link:,
        code:,
        code_to_match: user_site.sign_in_code,
        add_failed_attempt: -> { user_site.add_sign_in_code_failed_attempt },
        are_max_attempts_reached: -> { user_site.sign_in_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_sign_in_attrs_then_send_it(delivery_method:, keep_signed_in:) }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the email has a syntax error
    def render_email_syntax_error(email:)
      HawthorneCore::UserAction::Log.sign_in_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
    end

    # ---------------------------------------------------------------------------

  end

end