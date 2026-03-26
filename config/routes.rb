HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  get 'verify-pin', to: 'user/session#verify_pin_show'
  post 'verify-pin', to: 'user/session#verify_pin'

  get 'verify-pin-via-magic-link', to: 'user/session#verify_pin',  defaults: { pin_delivery_method: HawthorneCore::User::PIN_VIA_EMAIL, from_magic_link: true }

  # ----------------------

  get 'account', to: 'user#show'

  # ----------------------------------------------------------------------------

end