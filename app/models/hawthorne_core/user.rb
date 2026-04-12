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

  def first_name = full_name.present? ? full_name.split(' ').first : ''

  def first_name? = full_name.present?

  def sign_in_pin_default_delivery_pretty_print
    if sign_in_pin_default_delivery_via_email?
      'Email'
    elsif sign_in_pin_default_delivery_via_phone?
      'Text Message'
    end
  end

  # -----------------------------------------------------------------------------

  # clear the users phone number,
  # and set the sign-in pin default delivery to EMAIL as they no longer have a phone number
  def clear_phone_number
    update_columns(phone_number: nil, sign_in_pin_default_delivery: HawthorneCore::User::PIN_VIA_EMAIL)
  end

  # -----------------------------------------------------------------------------

end