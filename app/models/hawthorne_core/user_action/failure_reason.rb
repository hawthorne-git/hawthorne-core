# v3.0

module HawthorneCore::UserAction::FailureReason

  # -----------------------------------------------------------------------------

  REASONS =
    {
      address_identical: 'ADDRESS IDENTICAL',
      code_expired: 'CODE EXPIRED',
      code_max_failed_attempts_reached: 'CODE MAX FAILED ATTEMPTS REACHED',
      code_not_match: 'CODE DOES NOT MATCH',
      code_not_set: 'CODE NOT SET',
      email_identical: 'EMAIL IDENTICAL',
      email_syntax_error: 'EMAIL SYNTAX ERROR',
      email_taken: 'EMAIL TAKEN',
      email_recently_sent: 'EMAIL RECENTLY SENT',
      exception_caught: 'EXCEPTION CAUGHT',
      phone_number_identical: 'PHONE NUMBER IDENTICAL',
      phone_number_syntax_error: 'PHONE NUMBER SYNTAX ERROR',
      stripe_payment_method_id_invalid: 'STRIPE PAYMENT METHOD INVALID',
      text_message_recently_sent: 'TEXT MESSAGE RECENTLY SENT',
      unexpected_state: 'UNEXPECTED STATE',
      user_not_found: 'USER NOT FOUND'
    }.freeze

  REASONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end