# v3.0XXX

module HawthorneCore::SiteUserAction::Log

  # -----------------------------------------------------------------------------

  ADMIN_IP = 'ADMIN'
  ADMIN_TOKEN = 'ADMIN'

  # ----------------------------------------------------------------------------- Braintree - User

  def self.braintree_customer_id_attached(site_user_id, note)
    success_admin(site_user_id, action(:braintree_customer_id_attached), note)
  end

  def self.braintree_customer_id_attached_failure(site_user_id, failure_reason, note)
    failure_admin(site_user_id, action(:braintree_customer_id_attached), failure_reason, note)
  end

  # ----------------------------------------------------------------------------- Email

  def self.email_sent(site_user_id, note)
    success_admin(site_user_id, action(:email_sent), note)
  end

  def self.email_sent_failure(site_user_id, failure_reason, note)
    failure_admin(site_user_id, action(:email_sent), failure_reason, note)
  end

  # ----------------------------------------------------------------------------- Email Address - Verified

  def self.email_address_verified(site_user_id, note)
    success_admin(site_user_id, action(:email_address_verified), note)
  end

  # ----------------------------------------------------------------------------- Pin

  def self.pin_cleared(site_user_id)
    success_admin(site_user_id, action(:pin_cleared), nil)
  end

  # ------------------------

  def self.pin_created(site_user_id, note)
    success_admin(site_user_id, action(:pin_created), note)
  end

  # ------------------------

  def self.pin_verified(site_user_id, ip_address, site_user_token)
    success(site_user_id, action(:pin_verified), nil, ip_address, site_user_token)
  end

  def self.pin_verified_failure(site_user_id, failure_reason, note, ip_address, site_user_token)
    failure(site_user_id, action(:pin_verified), failure_reason, note, ip_address, site_user_token)
  end

  # ----------------------------------------------------------------------------- Sign-In

  def self.sign_in(site_user_id)
    success_admin(site_user_id, action(:sign_in), nil)
  end

  # ----------------------------------------------------------------------------- Text Message

  def self.text_message_sent(site_user_id, note)
    success_admin(site_user_id, action(:text_message_sent), note)
  end

  def self.text_message_sent_failure(site_user_id, failure_reason, note)
    failure_admin(site_user_id, action(:text_message_sent), failure_reason, note)
  end

  # -----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------- Core logger
  # -----------------------------------------------------------------------------

  def self.log(site_user_id, action, success, failure_reason, note, ip_address, site_user_token)
    HawthorneCore::SiteUser::LogActionJob.perform_later(site_user_id, action, success, failure_reason, note, ip_address, site_user_token)
  end

  # ----------------------------------------------------------------------------- Helpers

  def self.success(site_user_id, action, note, ip_address, site_user_token)
    log(site_user_id, action, true, nil, note, ip_address, site_user_token)
  end

  def self.failure(site_user_id, action, failure_reason, note, ip_address, site_user_token)
    log(site_user_id, action, false, failure_reason, note, ip_address, site_user_token)
  end

  # ------------------------

  def self.success_admin(site_user_id, action, note)
    log(site_user_id, action, true, nil, note, ADMIN_IP, ADMIN_TOKEN)
  end

  def self.failure_admin(site_user_id, action, failure_reason, note)
    log(site_user_id, action, false, failure_reason, note, ADMIN_IP, ADMIN_TOKEN)
  end

  # ----------------------------------------------------------------------------- Actions

  # pull action string from actions module
  def self.action(key) =  HawthorneCore::SiteUserAction::Action::ACTIONS.fetch(key)

  # -----------------------------------------------------------------------------

end