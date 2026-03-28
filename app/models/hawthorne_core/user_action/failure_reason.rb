# v3.0

module HawthorneCore::UserAction::FailureReason

  # -----------------------------------------------------------------------------

  REASONS =
    {
      email_identical: 'EMAIL IDENTICAL',
      email_recently_sent: 'EMAIL RECENTLY SENT',
      email_syntax_error: 'EMAIL SYNTAX ERROR',
      email_taken: 'EMAIL TAKEN',
      exception_caught: 'EXCEPTION_CAUGHT',
      pin_expired: 'PIN EXPIRED',
      pin_max_failed_attempts_reached: 'PIN MAX FAILED ATTEMPTS REACHED',
      pin_not_match: 'PIN DOES NOT MATCH',
      pin_not_set: 'PIN NOT SET',
      phone_number_syntax_error: 'PHONE NUMBER SYNTAX ERROR',
      unexpected_state: 'UNEXPECTED_STATE',
      user_not_created: 'USER NOT CREATED',
      user_not_found: 'USER NOT FOUND'
    }.freeze

  REASONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end