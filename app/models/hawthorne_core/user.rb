# v3.0

class HawthorneCore::User < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::User::EmailVerification,
          HawthorneCore::User::PinVerification,
          HawthorneCore::User::PaymentMethods,
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

  # -----------------------------------------------------------------------------

  # get the sign in pin default delivery, in a prettier format then what is saved in the database
  def sign_in_pin_default_delivery_pretty_print
    return 'Email' if sign_in_pin_default_delivery_via_email?
    return 'Text Message' if sign_in_pin_default_delivery_via_phone?
    nil
  end

  # -----------------------------------------------------------------------------

  # determine if a specific user id is deleted
  def self.deleted?(user_id:) = exists?(user_id: user_id, deleted: true)

  # -----------------------------------------------------------------------------

  # removes a users phone number - which is just updating it to nil
  def remove_phone_number = update_phone_number(new_phone_number: nil)

  # updates a users phone number
  # if the phone number is present, update the sign-in pin delivery to text message, else via email
  def update_phone_number(new_phone_number:)
    new_sign_in_pin_default_delivery = (new_phone_number.present? ? HawthorneCore::User::PIN_VIA_PHONE : HawthorneCore::User::PIN_VIA_EMAIL)
    update(phone_number: new_phone_number, sign_in_pin_default_delivery: new_sign_in_pin_default_delivery)
    HawthorneCore::UserAction::Log.update_profile_phone_number(note: { old: phone_number_before_last_save, new: new_phone_number })
    HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_pin_default_delivery: sign_in_pin_default_delivery_before_last_save, new_sign_in_pin_default_delivery: new_sign_in_pin_default_delivery }) if sign_in_pin_default_delivery_previously_changed?
  end

  # -----------------------------------------------------------------------------

end