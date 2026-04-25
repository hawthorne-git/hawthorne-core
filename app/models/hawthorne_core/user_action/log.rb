# v3.0

module HawthorneCore::UserAction::Log

  # ----------------------------------------------------------------------------- Account

  def self.account_created(user_id, note, ip_address, user_session_token)
    success(user_id, action(:account_created), note, ip_address, user_session_token)
  end


  # ----------------------------------------------------------------------------- Account (Delete)

  def self.delete_account_attrs_cleared(user_id)
    success_admin(user_id, action(:delete_account_attrs_cleared), nil)
  end

  def self.delete_account_attrs_refreshed(user_id, note)
    success_admin(user_id, action(:delete_account_attrs_refreshed), note)
  end

  def self.delete_account_attrs_set(user_id, note)
    success_admin(user_id, action(:delete_account_attrs_set), note)
  end

  # ------------------------

  def self.delete_account(user_id, ip_address, user_session_token)
    success(user_id, action(:account_deleted), nil, ip_address, user_session_token)
  end

  def self.delete_account_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:account_deleted), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Credit Card

  def self.add_credit_card(user_id, note, ip_address, user_session_token)
    success(user_id, action(:credit_card_added), note, ip_address, user_session_token)
  end

  def self.add_credit_card_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:credit_card_added), failure_reason, note, ip_address, user_session_token)
  end

  def self.remove_credit_card(user_id, note, ip_address, user_session_token)
    success(user_id, action(:credit_card_removed), note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Email

  def self.email_sent(user_id, note)
    success_admin(user_id, action(:email_sent), note)
  end

  def self.email_sent_failure(user_id, failure_reason, note)
    failure_admin(user_id, action(:email_sent), failure_reason, note)
  end

  # ------------------------

  def self.email_address_verified(user_id, note)
    success_admin(user_id, action(:email_address_verified), note)
  end

  # ----------------------------------------------------------------------------- Email (Update)

  def self.new_email_address_attrs_cleared(user_id)
    success_admin(user_id, action(:email_address_update_attrs_cleared), nil)
  end

  def self.new_email_address_attrs_refreshed(user_id, note)
    success_admin(user_id, action(:email_address_update_attrs_refreshed), note)
  end

  def self.new_email_address_attrs_set(user_id, note)
    success_admin(user_id, action(:email_address_update_attrs_set), note)
  end

  # ----------------------------------------------------------------------------- Phone (Update)

  def self.new_phone_number_attrs_cleared(user_id)
    success_admin(user_id, action(:phone_number_update_attrs_cleared), nil)
  end

  def self.new_phone_number_attrs_refreshed(user_id, note)
    success_admin(user_id, action(:phone_number_update_attrs_refreshed), note)
  end

  def self.new_phone_number_attrs_set(user_id, note)
    success_admin(user_id, action(:phone_number_update_attrs_set), note)
  end

  # ----------------------------------------------------------------------------- Profile

  def self.update_profile(**attrs) = success(**attrs, action: action(:profile_updated))

  # ------------------------

  def self.update_profile_email_address(user_id, note, ip_address, user_session_token)
    success(user_id, action(:profile_email_address_updated), note, ip_address, user_session_token)
  end

  def self.update_profile_email_address_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:profile_email_address_updated), failure_reason, note, ip_address, user_session_token)
  end

  # ------------------------

  def self.update_profile_phone_number(user_id, note, ip_address, user_session_token)
    success(user_id, action(:profile_phone_number_updated), note, ip_address, user_session_token)
  end

  def self.update_profile_phone_number_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:profile_phone_number_updated), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Sign-In

  def self.sign_in(user_id)
    success_admin(user_id, action(:sign_in), nil)
  end

  def self.sign_in_failure(failure_reason, note, ip_address, user_session_token)
    failure(nil, action(:sign_in), failure_reason, note, ip_address, user_session_token)
  end

  # ------------------------

  def self.sign_in_via_cookie(user_id, note)
    success_admin(user_id, action(:sign_in_via_cookie), note)
  end

  # ----------------------------------------------------------------------------- Sign-In Pin

  def self.sign_in_pin_cleared(user_id)
    success_admin(user_id, action(:sign_in_pin_cleared), nil)
  end

  # ------------------------

  def self.sign_in_pin_created(user_id, note)
    success_admin(user_id, action(:sign_in_pin_created), note)
  end

  # ------------------------

  def self.sign_in_pin_verified(user_id, ip_address, user_session_token)
    success(user_id, action(:sign_in_pin_verified), nil, ip_address, user_session_token)
  end

  def self.sign_in_pin_verified_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:sign_in_pin_verified), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Sign-Out

  def self.sign_out(user_id, ip_address, user_session_token)
    success(user_id, action(:sign_out), nil, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Shipping Address

  def self.add_shipping_address(user_id, note, ip_address, user_session_token)
    success(user_id, action(:shipping_address_added), note, ip_address, user_session_token)
  end

  # ------------------------

  def self.update_shipping_address(user_id, note, ip_address, user_session_token)
    success(user_id, action(:shipping_address_updated), note, ip_address, user_session_token)
  end

  # ------------------------

  def self.remove_shipping_address(user_id, note, ip_address, user_session_token)
    success(user_id, action(:shipping_address_removed), note, ip_address, user_session_token)
  end

  # ------------------------

  def self.shipping_address_failure(user_id, failure_reason, note, ip_address, user_session_token)
    failure(user_id, action(:shipping_address), failure_reason, note, ip_address, user_session_token)
  end

  # ----------------------------------------------------------------------------- Stripe

  def self.stripe_credit_card_created(user_id, note)
    success_admin(user_id, action(:stripe_credit_card_created), note)
  end

  def self.stripe_credit_card_detached(user_id, note)
    success_admin(user_id, action(:stripe_credit_card_detached), note)
  end

  def self.stripe_customer_created(user_id, note)
    success_admin(user_id, action(:stripe_customer_created), note)
  end

  def self.stripe_customer_email_address_updated(user_id, note)
    success_admin(user_id, action(:stripe_customer_email_address_updated), note)
  end

  def self.stripe_setup_intent_created(user_id, note)
    success_admin(user_id, action(:stripe_setup_intent_created), note)
  end

  # ----------------------------------------------------------------------------- Text Message

  def self.text_message_sent(user_id, note)
    success_admin(user_id, action(:text_message_sent), note)
  end

  def self.text_message_sent_failure(user_id, failure_reason, note)
    failure_admin(user_id, action(:text_message_sent), failure_reason, note)
  end

  # -----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------- Core Logger
  # -----------------------------------------------------------------------------

  def self.log(**attrs) = HawthorneCore::User::LogActionJob.perform_later(**attrs)

  # ------------------------

  def self.success_failure(failure_reason: nil, **attrs) = log(**attrs, failure_reason:, **HawthorneCore::RequestContext.get)

  def self.success(**attrs) = success_failure(**attrs, success: true)

  def self.failure(**attrs) = success_failure(**attrs, success: false)

  # ------------------------

  def self.success_admin(user_id, action, note)
    log(user_id, action, true, nil, note, 'ADMIN', 'ADMIN')
  end

  def self.failure_admin(user_id, action, failure_reason, note)
    log(user_id, action, false, failure_reason, note, 'ADMIN', 'ADMIN')
  end

  # ----------------------------------------------------------------------------- Action Lookup

  # fetch action string from actions module
  def self.action(key) = HawthorneCore::UserAction::Action::ACTIONS.fetch(key)

  # -----------------------------------------------------------------------------

end