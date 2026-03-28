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

  get 'profile-email-address-update', to: 'user/profile#email_address_update_show'
  post 'profile-email-address-update-validation', to: 'user/profile#email_address_update_validation'
  get 'profile-email-address-update-verify-pin', to: 'user/profile#email_address_update_verify_pin_show'
  post 'profile-email-address-update-verify-pin', to: 'user/profile#email_address_update_verify_pin'

  # ----------------------

  get 'sign-out', to: 'user/session#sign_out'

  # ----------------------------------------------------------------------------

end