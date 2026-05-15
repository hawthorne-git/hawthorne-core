module HawthorneCore::Validation::PhoneNumber
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # render an error message that the phone number code is inactive
    def render_phone_number_code_inactive_error(user_site:)
      render_code_inactive_error(
        note: { new_phone_number_code: user_site.new_phone_number_code, new_phone_number_code_created_at: user_site.new_phone_number_code_created_at, new_phone_number_code_failed_attempts_count: user_site.new_phone_number_code_failed_attempts_count },
        is_code_set: -> { user_site.new_phone_number_code_set? },
        is_code_expired: -> { user_site.new_phone_number_code_expired? },
        are_max_attempts_reached: -> { user_site.new_phone_number_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_new_phone_number_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the phone number code does not match
    def render_phone_number_code_not_match_error(user_site:, code:)
      render_code_not_match_error(
        action: 'UPDATE_PHONE_NUMBER',
        code:,
        code_to_match: user_site.new_phone_number_code,
        add_failed_attempt: -> { user_site.add_new_phone_number_code_failed_attempt },
        are_max_attempts_reached: -> { user_site.new_phone_number_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_new_phone_number_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the new phone number is identical to the current phone number
    def render_phone_number_identical_error(phone_number:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_identical, note: { phone_number: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { identical: true })
    end

    # ---------------------------------------------------------------------------

    # render an error message that the phone number has a syntax error
    def render_phone_number_syntax_error(phone_number:)
      HawthorneCore::UserAction::Log.update_profile_failure(failure_reason: HawthorneCore::UserAction::FailureReason.phone_number_syntax_error, note: { phone_number: })
      render turbo_stream: turbo_stream.update('form_errors', partial: 'failed', locals: { syntax_error: true })
    end

    # ---------------------------------------------------------------------------

  end

end