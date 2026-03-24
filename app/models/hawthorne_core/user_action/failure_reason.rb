# v3.0

module HawthorneCore::UserAction::FailureReason

  # -----------------------------------------------------------------------------

  REASONS =
    {
      email_syntax_error: 'EMAIL SYNTAX ERROR',
      email_taken: 'EMAIL TAKEN',
      exception_caught: 'EXCEPTION_CAUGHT',
      pin_expired: 'PIN EXPIRED',
      pin_not_match: 'PIN DOES NOT MATCH',
      phone_number_syntax_error: 'PHONE NUMBER SYNTAX ERROR',
      site_user_not_created: 'SITE USER NOT CREATED',
      site_user_not_found: 'SITE USER NOT FOUND',
      unexpected_state: 'UNEXPECTED_STATE'
    }.freeze

  REASONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end