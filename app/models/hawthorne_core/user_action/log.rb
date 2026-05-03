# v3.0

module HawthorneCore::UserAction::Log

  # ----------------------------------------------------------------------------- Account

  def self.account_created(**attrs) = success(**attrs, action: action(:account_created))

  def self.account_deleted(**attrs) = success(**attrs, action: action(:account_deleted))

  # ----------------------------------------------------------------------------- Address

  def self.add_address(**attrs) = success(**attrs, action: action(:address_added))

  def self.update_address(**attrs) = success(**attrs, action: action(:address_updated))

  def self.remove_address(**attrs) = success(**attrs, action: action(:address_removed))

  def self.address_failure(**attrs) = failure(**attrs, action: action(:address))

  # ----------------------------------------------------------------------------- Code Attrs - Delete Account

  def self.delete_account_attrs_cleared(**attrs) = success_admin(**attrs, action: action(:delete_account_attrs_cleared))

  def self.delete_account_attrs_refreshed(**attrs) = success_admin(**attrs, action: action(:delete_account_attrs_refreshed))

  def self.delete_account_attrs_set(**attrs) = success_admin(**attrs, action: action(:delete_account_attrs_set))

  # ----------------------------------------------------------------------------- Code Attrs - Sign-In

  def self.sign_in_attrs_cleared(**attrs) = success_admin(**attrs, action: action(:sign_in_attrs_cleared))

  def self.sign_in_attrs_refreshed(**attrs) = success_admin(**attrs, action: action(:sign_in_attrs_refreshed))

  def self.sign_in_attrs_set(**attrs) = success_admin(**attrs, action: action(:sign_in_attrs_set))

  # ----------------------------------------------------------------------------- Code Attrs - Update Email

  def self.new_email_attrs_cleared(**attrs) = success_admin(**attrs, action: action(:email_update_attrs_cleared))

  def self.new_email_attrs_refreshed(**attrs) = success_admin(**attrs, action: action(:email_update_attrs_refreshed))

  def self.new_email_attrs_set(**attrs) = success_admin(**attrs, action: action(:email_update_attrs_set))

  # ----------------------------------------------------------------------------- Code Attrs - Update Phone Number

  def self.new_phone_number_attrs_cleared(**attrs) = success_admin(**attrs, action: action(:phone_number_update_attrs_cleared))

  def self.new_phone_number_attrs_refreshed(**attrs) = success_admin(**attrs, action: action(:phone_number_update_attrs_refreshed))

  def self.new_phone_number_attrs_set(**attrs) = success_admin(**attrs, action: action(:phone_number_update_attrs_set))

  # ----------------------------------------------------------------------------- Credit Card

  def self.add_credit_card(user_id, note)
    success(user_id, action(:credit_card_added), note)
  end

  def self.add_credit_card_failure(user_id, failure_reason, note)
    failure(user_id, action(:credit_card_added), failure_reason, note)
  end

  def self.remove_credit_card(user_id, note)
    success(user_id, action(:credit_card_removed), note)
  end

  # ----------------------------------------------------------------------------- Email

  def self.email_sent(**attrs) = success_admin(**attrs, action: action(:email_sent))

  def self.email_sent_failure(**attrs) = failure_admin(**attrs, action: action(:email_sent))

  # ----------------------------------------------------------------------------- Profile

  def self.update_profile(**attrs) = success(**attrs, action: action(:profile_updated))

  def self.update_profile_failure(**attrs) = failure(**attrs, action: action(:profile_updated))

  # ----------------------------------------------------------------------------- Sign-In / Sign-Out

  def self.sign_in(**attrs) = success(**attrs, action: action(:sign_in))

  def self.sign_in_failure(**attrs) = failure(**attrs, action: action(:sign_in))

  def self.sign_in_via_cookie(**attrs) = success_admin(**attrs, action: action(:sign_in_via_cookie))

  def self.sign_out(**attrs) = success(**attrs, action: action(:sign_out))


  # ----------------------------------------------------------------------------- Stripe

  def self.stripe_credit_card_created(**attrs) = success_admin(**attrs, action: action(:stripe_credit_card_created))

  def self.stripe_credit_card_detached(**attrs) = success_admin(**attrs, action: action(:stripe_credit_card_detached))

  def self.stripe_customer_created(**attrs) = success_admin(**attrs, action: action(:stripe_customer_created))

  def self.stripe_customer_email_updated(**attrs) = success_admin(**attrs, action: action(:stripe_customer_email_updated))

  def self.stripe_setup_intent_created(**attrs) = success_admin(**attrs, action: action(:stripe_setup_intent_created))

  # ----------------------------------------------------------------------------- Text Message

  def self.text_message_sent(**attrs) = success_admin(**attrs, action: action(:text_message_sent))

  def self.text_message_sent_failure(**attrs) = failure_admin(**attrs, action: action(:text_message_sent))

  # -----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------- Core Logger
  # -----------------------------------------------------------------------------

  def self.log(**attrs) = HawthorneCore::User::LogActionJob.perform_later(**attrs)

  # ------------------------

  def self.success_failure(failure_reason: nil, **attrs) = log(**attrs, failure_reason:, **HawthorneCore::RequestContext.get)

  def self.success(**attrs) = success_failure(**attrs, success: true)

  def self.failure(**attrs) = success_failure(**attrs, success: false)

  # ------------------------

  def self.success_failure_admin(failure_reason: nil, **attrs)
    user_id = HawthorneCore::RequestContext.get[:user_id].presence || attrs[:user_id]
    log(**attrs, failure_reason:, user_id:, ip: 'ADMIN', user_session_token: 'ADMIN')
  end

  def self.success_admin(**attrs) = success_failure_admin(**attrs, success: true)

  def self.failure_admin(**attrs) = success_failure_admin(**attrs, success: false)

  # ----------------------------------------------------------------------------- Action Lookup

  # fetch action string from actions module
  def self.action(key) = HawthorneCore::UserAction::Action::ACTIONS.fetch(key)

  # -----------------------------------------------------------------------------

end