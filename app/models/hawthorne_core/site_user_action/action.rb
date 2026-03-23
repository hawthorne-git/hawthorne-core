# v3.0

module HawthorneCore::SiteUserAction::Action

  # -----------------------------------------------------------------------------

  ACTIONS =
    {
      braintree_customer_id_attached: 'BRAINTREE CUSTOMER ID ATTACHED',
      email_sent: 'EMAIL SENT',
      email_address_verified: 'EMAIL ADDRESS VERIFIED',
      pin_cleared: 'PIN CLEARED',
      pin_created: 'PIN CREATED',
      pin_verified: 'PIN VERIFIED',
      sign_in: 'SIGN-IN',
      text_message_sent: 'TEXT MESSAGE SENT'
    }.freeze

  ACTIONS.each do |key, value|
    define_singleton_method(key) { value }
  end

  # -----------------------------------------------------------------------------

end