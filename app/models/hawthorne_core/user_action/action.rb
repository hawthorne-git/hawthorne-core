# v3.0

module HawthorneCore::UserAction::Action

  # -----------------------------------------------------------------------------

  ACTIONS =
    {
      account_created: 'ACCOUNT CREATED',
      email_sent: 'EMAIL SENT',
      email_address_verified: 'EMAIL ADDRESS VERIFIED',
      email_address_update_attrs_cleared: 'EMAIL ADDRESS UPDATE ATTRIBUTES CLEARED',
      email_address_update_attrs_refreshed: 'EMAIL ADDRESS UPDATE ATTRIBUTES REFRESHED',
      email_address_update_attrs_set: 'EMAIL ADDRESS UPDATE ATTRIBUTES SET',
      phone_number_update_attrs_cleared: 'PHONE NUMBER UPDATE ATTRIBUTES CLEARED',
      phone_number_update_attrs_refreshed: 'PHONE NUMBER UPDATE ATTRIBUTES REFRESHED',
      phone_number_update_attrs_set: 'PHONE NUMBER UPDATE ATTRIBUTES SET',
      profile_updated: 'PROFILE UPDATED',
      profile_email_address_updated: 'PROFILE EMAIL ADDRESS UPDATED',
      profile_phone_number_updated: 'PROFILE PHONE NUMBER UPDATED',
      shipping_address: 'SHIPPING ADDRESS',
      shipping_address_added: 'SHIPPING ADDRESS ADDED',
      shipping_address_removed: 'SHIPPING ADDRESS REMOVED',
      shipping_address_updated: 'SHIPPING ADDRESS UPDATED',
      sign_in: 'SIGN-IN',
      sign_in_pin_cleared: 'SIGN-IN PIN CLEARED',
      sign_in_pin_created: 'SIGN-IN PIN CREATED',
      sign_in_pin_verified: 'SIGN-IN PIN VERIFIED',
      sign_in_via_cookie: 'SIGN-IN VIA COOKIE',
      sign_out: 'SIGN-OUT',
      text_message_sent: 'TEXT MESSAGE SENT'
    }.freeze

  ACTIONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end