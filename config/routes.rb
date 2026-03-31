HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  get 'verify-pin', to: 'user/session#verify_pin_show'
  get 'verify-pin-via-magic-link', to: 'user/session#verify_pin',  defaults: { pin_delivery_method: HawthorneCore::User::PIN_VIA_EMAIL, from_magic_link: true }
  post 'verify-pin', to: 'user/session#verify_pin'
  get 'resend-pin', to: 'user/session#resend_pin'
  get 'resend-pin-via-email', to: 'user/session#resend_pin_via_email'
  get 'resend-pin-via-text', to: 'user/session#resend_pin_via_phone'

  # ----------------------

  get 'account', to: 'user#show'

  # ----------------------

  get 'profile', to: 'user/profile#show'
  post 'profile', to: 'user/profile#update'

  get 'profile-email-address', to: 'user/profile/email_address#show'
  post 'profile-email-address-verify', to: 'user/profile/email_address#verify'
  get 'profile-email-address-verify-pin', to: 'user/profile/email_address#verify_pin_show'
  post 'profile-email-address-verify-pin', to: 'user/profile/email_address#verify_pin'
  get 'profile-email-address-resend-pin', to: 'user/profile/email_address#resend_pin'

  get 'profile-phone-number', to: 'user/profile/phone_number#show'
  post 'profile-phone-number-verify', to: 'user/profile/phone_number#verify'
  get 'profile-phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin_show'
  post 'profile-phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin'
  get 'profile-phone-number-resend-pin', to: 'user/profile/phone_number#resend_pin'
  delete 'profile-phone-number-clear', to: 'user/profile/phone_number#clear'

  # ----------------------

  get 'add-shipping-address', to: 'user/shipping_address#new'
  post 'add-shipping-address', to: 'user/shipping_address#create'

  # ----------------------

  get 'sign-out', to: 'user/session#sign_out'

  # ----------------------------------------------------------------------------

end