# v3.0

module HawthorneCore::UserAction::Action

  # -----------------------------------------------------------------------------

  ACTIONS =
    {
      account_created: 'ACCOUNT CREATED',
      email_sent: 'EMAIL SENT',
      email_address_verified: 'EMAIL ADDRESS VERIFIED',
      email_address_update_attrs_cleared: 'EMAIL ADDRESS UPDATE ATTRIBUTES CLEARED',
      email_address_update_attrs_set: 'EMAIL ADDRESS UPDATE ATTRIBUTES SET',
      phone_number_update_attrs_cleared: 'PHONE NUMBER UPDATE ATTRIBUTES CLEARED',
      phone_number_update_attrs_set: 'PHONE NUMBER UPDATE ATTRIBUTES SET',
      pin_cleared: 'PIN CLEARED',
      pin_created: 'PIN CREATED',
      pin_verified: 'PIN VERIFIED',
      profile_updated: 'PROFILE UPDATED',
      profile_email_updated: 'PROFILE EMAIL UPDATED',
      sign_in: 'SIGN-IN',
      sign_in_via_cookie: 'SIGN-IN VIA COOKIE',
      sign_out: 'SIGN-OUT',
      text_message_sent: 'TEXT MESSAGE SENT'
    }.freeze

  ACTIONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end