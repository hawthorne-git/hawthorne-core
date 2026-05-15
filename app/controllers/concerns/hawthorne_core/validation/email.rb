module HawthorneCore::Validation::Email
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # render an error message that the code is inactive
    def render_email_code_inactive_error(user_site:)
      render_code_inactive_error(
        note: { new_email_code: user_site.new_email_code, new_email_code_created_at: user_site.new_email_code_created_at, new_email_code_failed_attempts_count: user_site.new_email_code_failed_attempts_count },
        is_code_set: -> { user_site.new_email_code_set? },
        is_code_expired: -> { user_site.new_email_code_expired? },
        are_max_attempts_reached: -> { user_site.new_email_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_new_email_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the code does not match
    def render_email_code_not_match_error(user_site:, code:)
      render_code_not_match_error(
        action: 'UPDATE_EMAIL',
        code:,
        code_to_match: user_site.new_email_code,
        add_failed_attempt: -> { user_site.add_new_email_code_failed_attempt },
        are_max_attempts_reached: -> { user_site.new_email_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_new_email_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the new email is identical to the current email
    def render_email_identical_error(email:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_identical, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true })
    end

    # ---------------------------------------------------------------------------

    # render an error message that the email has a syntax error
    def render_email_syntax_error(email:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_syntax_error, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
    end
    # ---------------------------------------------------------------------------


    # render an error message that the email is taken
    def render_email_taken_error(email:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.email_taken, note: { email: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { taken: true })
    end

    # ---------------------------------------------------------------------------

  end

end