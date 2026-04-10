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

  def first_name = full_name.split(' ').first

  def first_name? = first_name.present?

  # -----------------------------------------------------------------------------

  # clear the users phone number,
  # and set the sign-in pin default delivery to EMAIL as they no longer have a phone number
  def clear_phone_number
    update_columns(phone_number: nil, sign_in_pin_default_delivery: HawthorneCore::User::PIN_VIA_EMAIL)
  end

  # -----------------------------------------------------------------------------

end