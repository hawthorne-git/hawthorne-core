# v3.0

module HawthorneCore::User::PhoneNumber
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # clear the users new phone number attributes, which is site specific
    def clear_new_phone_number_attrs = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id: id, site_id: HawthorneCore::Site.this_site_id).clear_new_phone_number_attrs

    # set the users new phone number attributes, which is site specific
    def set_new_phone_number_attrs(new_phone_number:) = HawthorneCore::UserSite.select(:user_site_id).find_by(user_id: id, site_id: HawthorneCore::Site.this_site_id).set_new_phone_number_attrs(new_phone_number:)

    # -----------------------------------------------------------------------------

    def new_phone_number_attr = HawthorneCore::UserSite.where(user_id: id, site_id: HawthorneCore::Site.this_site_id).pick(:new_phone_number)

    # -----------------------------------------------------------------------------

    # updates a users phone number
    # if the phone number is present, update the sign-in pin delivery to text message, else via email
    # lastly, clear their new phone number attributes
    def update_phone_number(new_phone_number:)
      new_sign_in_pin_default_delivery = (new_phone_number.present? ? HawthorneCore::User::PIN_VIA_PHONE : HawthorneCore::User::PIN_VIA_EMAIL)
      update(phone_number: new_phone_number, sign_in_pin_default_delivery: new_sign_in_pin_default_delivery)
      HawthorneCore::UserAction::Log.update_profile_phone_number(note: { old: phone_number_before_last_save, new: new_phone_number })
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_pin_default_delivery: sign_in_pin_default_delivery_before_last_save, new_sign_in_pin_default_delivery: new_sign_in_pin_default_delivery }) if sign_in_pin_default_delivery_previously_changed?
      clear_new_phone_number_attrs
    end

    # removes a users phone number - which is just updating it to nil
    def remove_phone_number = update_phone_number(new_phone_number: nil)

    # -----------------------------------------------------------------------------

  end

end