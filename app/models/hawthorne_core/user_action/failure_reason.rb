# v3.0

module HawthorneCore::UserAction::FailureReason

  # -----------------------------------------------------------------------------

  REASONS =
    {
      email_address_identical: 'EMAIL ADDRESS IDENTICAL',
      email_address_syntax_error: 'EMAIL ADDRESS SYNTAX ERROR',
      email_address_taken: 'EMAIL ADDRESS TAKEN',
      email_recently_sent: 'EMAIL RECENTLY SENT',
      exception_caught: 'EXCEPTION CAUGHT',
      pin_expired: 'PIN EXPIRED',
      pin_max_failed_attempts_reached: 'PIN MAX FAILED ATTEMPTS REACHED',
      pin_not_match: 'PIN DOES NOT MATCH',
      pin_not_set: 'PIN NOT SET',
      phone_number_identical: 'PHONE NUMBER IDENTICAL',
      phone_number_syntax_error: 'PHONE NUMBER SYNTAX ERROR',
      shipping_address_identical: 'SHIPPING ADDRESS IDENTICAL',
      text_message_recently_sent: 'TEXT MESSAGE RECENTLY SENT',
      unexpected_state: 'UNEXPECTED STATE',
      user_not_found: 'USER NOT FOUND'
    }.freeze

  REASONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end