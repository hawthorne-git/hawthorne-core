# v3.0

module HawthorneCore::User::PhoneNumber
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # get the users phone number
    def self.phone_number(user_id:) = where(user_id:).pick(:phone_number)

    # -----------------------------------------------------------------------------

    # clear the users new phone number attributes, which is site specific
    def clear_new_phone_number_attrs = user_site.clear_new_phone_number_attrs
    def self.clear_new_phone_number_attrs(user_id:) = user_site(user_id:).clear_new_phone_number_attrs

    # set the users new phone number attributes, which is site specific, then send the code via text message
    def self.set_new_phone_number_attrs_then_send_it(user_id:, phone_number:) = user_site(user_id:).set_new_phone_number_attrs_then_send_it(new_phone_number: phone_number)

    # -----------------------------------------------------------------------------

    # updates a users phone number
    # if the phone number is present, update the sign-in code delivery to text message, else email
    # lastly, clear their new phone number attributes
    def update_phone_number(phone_number:)
      update(phone_number:, sign_in_code_default_delivery: (phone_number.present? ? HawthorneCore::User::CODE_VIA_PHONE : HawthorneCore::User::CODE_VIA_EMAIL))
      HawthorneCore::UserAction::Log.update_profile(note: { old_phone_number: phone_number_before_last_save, phone_number: })
      HawthorneCore::UserAction::Log.update_profile(note: { old_sign_in_code_default_delivery: sign_in_code_default_delivery_before_last_save, sign_in_code_default_delivery: }) if sign_in_code_default_delivery_previously_changed?
      clear_new_phone_number_attrs
    end
    def self.update_phone_number(user_id:, phone_number:) = find_by(user_id:).update_phone_number(phone_number:)

    # removes a users phone number - which is simply updating it to nil
    def remove_phone_number = update_phone_number(phone_number: nil)
    def self.remove_phone_number(user_id:) = find_by(user_id:).remove_phone_number

    # -----------------------------------------------------------------------------

  end

end