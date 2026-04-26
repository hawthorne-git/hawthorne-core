# v3.0

module HawthorneCore::UserAction::Action

  # -----------------------------------------------------------------------------

  ACTIONS =
    {
      account_created: 'ACCOUNT CREATED',
      account_deleted: 'ACCOUNT DELETED',
      credit_card_added: 'CREDIT CARD ADDED',
      credit_card_removed: 'CREDIT CARD REMOVED',
      delete_account_attrs_cleared: 'DELETE ACCOUNT ATTRIBUTES CLEARED',
      delete_account_attrs_refreshed: 'DELETE ACCOUNT ATTRIBUTES REFRESHED',
      delete_account_attrs_set: 'DELETE ACCOUNT ATTRIBUTES SET',
      email_sent: 'EMAIL SENT',
      email_update_attrs_cleared: 'EMAIL UPDATE ATTRIBUTES CLEARED',
      email_update_attrs_refreshed: 'EMAIL UPDATE ATTRIBUTES REFRESHED',
      email_update_attrs_set: 'EMAIL UPDATE ATTRIBUTES SET',
      email_verified: 'EMAIL VERIFIED',
      phone_number_update_attrs_cleared: 'PHONE NUMBER UPDATE ATTRIBUTES CLEARED',
      phone_number_update_attrs_refreshed: 'PHONE NUMBER UPDATE ATTRIBUTES REFRESHED',
      phone_number_update_attrs_set: 'PHONE NUMBER UPDATE ATTRIBUTES SET',
      profile_updated: 'PROFILE UPDATED',
      shipping_address: 'SHIPPING ADDRESS',
      shipping_address_added: 'SHIPPING ADDRESS ADDED',
      shipping_address_removed: 'SHIPPING ADDRESS REMOVED',
      shipping_address_updated: 'SHIPPING ADDRESS UPDATED',
      sign_in: 'SIGN-IN',
      sign_in_code_cleared: 'SIGN-IN CODE CLEARED',
      sign_in_code_created: 'SIGN-IN CODE CREATED',
      sign_in_code_verified: 'SIGN-IN CODE VERIFIED',
      sign_in_via_cookie: 'SIGN-IN VIA COOKIE',
      sign_out: 'SIGN-OUT',
      stripe_credit_card_created: 'STRIPE CREDIT CARD CREATED',
      stripe_credit_card_detached: 'STRIPE CREDIT CARD DETACHED',
      stripe_customer_created: 'STRIPE CUSTOMER CREATED',
      stripe_customer_email_updated: 'STRIPE CUSTOMER EMAIL UPDATED',
      stripe_setup_intent_created: 'STRIPE SETUP INTERNET CREATED',
      text_message_sent: 'TEXT MESSAGE SENT'
    }.freeze

  ACTIONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end