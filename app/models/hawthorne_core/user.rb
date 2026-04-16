# v3.0

class HawthorneCore::User < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::User::EmailVerification,
          HawthorneCore::User::PinVerification,
          HawthorneCore::User::SingleSignOn,
          HawthorneCore::User::SiteAccess

  # -----------------------------------------------------------------------------

  self.table_name = 'users'

  def id = user_id

  # -----------------------------------------------------------------------------

  # get the first name of the user
  def first_name = full_name.present? ? full_name.split(' ').first : ''

  # determine if the user has a first name
  def first_name? = full_name.present?

  # determine if the user has a stripe customer account
  def stripe_customer? = stripe_customer_id.present?

  # -----------------------------------------------------------------------------

  # get the sign in pin default delivery, in a prettier format then what is saved in the database
  def sign_in_pin_default_delivery_pretty_print
    return 'Email' if sign_in_pin_default_delivery_via_email?
    return 'Text Message' if sign_in_pin_default_delivery_via_phone?
    nil
  end

  # -----------------------------------------------------------------------------

  # clear the users phone number,
  # and set the sign-in pin default delivery to EMAIL as they no longer have a phone number
  def clear_phone_number
    update_columns(phone_number: nil, sign_in_pin_default_delivery: HawthorneCore::User::PIN_VIA_EMAIL)
  end

  # -----------------------------------------------------------------------------

  # determine if a specific user id is deleted
  def self.deleted?(user_id) = exists?(user_id: user_id, deleted: true)

  # -----------------------------------------------------------------------------

end