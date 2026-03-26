# v3.0

module HawthorneCore::UserAction::Action

  # -----------------------------------------------------------------------------

  ACTIONS =
    {
      account_created: 'ACCOUNT CREATED',
      email_sent: 'EMAIL SENT',
      email_address_verified: 'EMAIL ADDRESS VERIFIED',
      pin_cleared: 'PIN CLEARED',
      pin_created: 'PIN CREATED',
      pin_verified: 'PIN VERIFIED',
      sign_in: 'SIGN-IN',
      sign_in_via_cookie: 'SIGN-IN VIA COOKIE',
      text_message_sent: 'TEXT MESSAGE SENT'
    }.freeze

  ACTIONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end