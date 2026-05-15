module HawthorneCore::Validation::DeleteAccount
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # render an error message that the code is inactive
    def render_delete_account_code_inactive_error(user_site:)
      render_code_inactive_error(
        note: { delete_account_code: user_site.delete_account_code, delete_account_code_created_at: user_site.delete_account_code_created_at, delete_account_code_failed_attempts_count: user_site.delete_account_code_failed_attempts_count },
        is_code_set: -> { user_site.delete_account_code_set? },
        is_code_expired: -> { user_site.delete_account_code_expired? },
        are_max_attempts_reached: -> { user_site.delete_account_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_delete_account_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

    # render an error message that the code does not match
    def render_delete_account_code_not_match_error(user_site:, code:)
      render_code_not_match_error(
        action: 'DELETE_ACCOUNT',
        code:,
        code_to_match: user_site.delete_account_code,
        add_failed_attempt: -> { user_site.add_delete_account_code_failed_attempt },
        are_max_attempts_reached: -> { user_site.delete_account_code_max_failed_attempts_reached? },
        refresh_attrs_then_send_it: -> { user_site.refresh_delete_account_attrs_then_send_it }
      )
    end

    # ---------------------------------------------------------------------------

  end

end