HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  get 'verify-sign-in-pin', to: 'user/session#verify_sign_in_pin_show'
  get 'verify-sign-in-pin-via-magic-link', to: 'user/session#verify_sign_in_pin',  defaults: { pin_delivery_method: HawthorneCore::User::PIN_VIA_EMAIL, from_magic_link: true }
  post 'verify-sign-in-pin', to: 'user/session#verify_sign_in_pin'
  get 'resend-sign-in-pin', to: 'user/session#resend_sign_in_pin'
  get 'resend-sign-in-pin-via-email', to: 'user/session#resend_sign_in_pin_via_email'
  get 'resend-sign-in-pin-via-text', to: 'user/session#resend_sign_in_pin_via_phone'

  # ----------------------

  get 'account', to: 'user#show'

  # ----------------------

  get 'account/profile', to: 'user/profile#show'
  post 'account/profile', to: 'user/profile#update'

  get 'account/profile/email-address', to: 'user/profile/email_address#show'
  post 'account/profile/email-address-verify', to: 'user/profile/email_address#verify'
  get 'account/profile/email-address-verify-pin', to: 'user/profile/email_address#verify_pin_show'
  post 'account/profile/email-address-verify-pin', to: 'user/profile/email_address#verify_pin'
  get 'account/profile/email-address-resend-pin', to: 'user/profile/email_address#resend_pin'

  get 'account/profile/phone-number', to: 'user/profile/phone_number#show'
  post 'account/profile/phone-number-verify', to: 'user/profile/phone_number#verify'
  get 'account/profile/phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin_show'
  post 'account/profile/phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin'
  get 'account/profile/phone-number-resend-pin', to: 'user/profile/phone_number#resend_pin'
  delete 'account/profile/phone-number-clear', to: 'user/profile/phone_number#clear'

  # ----------------------

  get 'account/add-shipping-address', to: 'user/shipping_address#new'
  get 'account/add-shipping-address-select-country', to: 'user/shipping_address#new_select_country'
  post 'account/add-shipping-address-with-selected-country', to: 'user/shipping_address#new_selected_country'
  post 'account/add-shipping-address', to: 'user/shipping_address#create'

  # ----------------------

  get 'sign-out', to: 'user/session#sign_out'

  # ----------------------------------------------------------------------------

end