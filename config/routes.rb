HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  get 'verify-pin', to: 'user/session#verify_pin_show'
  post 'verify-pin', to: 'user/session#verify_pin'

  get 'verify-pin-via-magic-link', to: 'user/session#verify_pin',  defaults: { pin_delivery_method: HawthorneCore::User::PIN_VIA_EMAIL, from_magic_link: true }

  # ----------------------

  get 'account', to: 'user#show'

  # ----------------------

  get 'profile', to: 'user/profile#show'
  post 'profile', to: 'user/profile#update'

  get 'profile-email-address-update', to: 'user/profile_email_address_update#show'
  post 'profile-email-address-update-verify', to: 'user/profile_email_address_update#verify'
  get 'profile-email-address-update-verify-pin', to: 'user/profile_email_address_update#verify_pin_show'
  get 'profile-email-address-update-resend-pin', to: 'user/profile_email_address_update#resend_pin'
  post 'profile-email-address-update-verify-pin', to: 'user/profile_email_address_update#verify_pin'

  get 'profile-phone-number-update', to: 'user/profile_phone_number_update#show'
  post 'profile-phone-number-update-verify', to: 'user/profile_phone_number_update#verify'
  get 'profile-phone-number-update-verify-pin', to: 'user/profile_phone_number_update#verify_pin_show'
  get 'profile-phone-number-update-resend-pin', to: 'user/profile_phone_number_update#resend_pin'
  post 'profile-phone-number-update-verify-pin', to: 'user/profile_phone_number_update#verify_pin'

  # ----------------------

  get 'sign-out', to: 'user/session#sign_out'

  # ----------------------------------------------------------------------------

end