HawthorneCore::Engine.routes.draw do

  # ----------------------------------------------------------------------------

  # ---------------------- ???

  #get 'sign-up', to: 'site_user/registration#sign_up_show'
  #post 'sign-up', to: 'site_user/registration#sign_up'

  #get 'validate-email-via-magic-link', to: 'site_user/registration#validate_email_via_magic_link'
  #get 'validate_email_via_magic_link_failure', to: 'site_user/registration#validate_email_via_magic_link_failure_show'

  #post 'validate-email-via-pin', to: 'site_user/registration#validate_email'

  #get 'welcome', to: 'home#welcome'

  # ----------------------

  get 'sign-in', to: 'site_user/session#sign_in_show'
  post 'sign-in', to: 'site_user/session#sign_in'

  get 'verify-pin', to: 'site_user/session#verify_pin_show'
  post 'verify-pin', to: 'site_user/session#verify_pin'

  get 'verify-pin-via-magic-link', to: 'site_user/session#verify_pin',  defaults: { pin_delivery_method: HawthorneCore::SiteUser::PIN_VIA_EMAIL, from_magic_link: true }

  # ----------------------

  get 'account', to: 'site_user#show'

  # ----------------------------------------------------------------------------

end