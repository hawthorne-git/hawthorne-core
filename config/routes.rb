HawthorneCore::Engine.routes.draw do

  # ----------------------------------------------------------------------------

  get 'sign-up', to: 'user/registration#sign_up_show'
  post 'sign-up', to: 'core/user#sign_up'
  get 'welcome', to: 'home#welcome'

  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user#sign_in'

  post 'core/webhook/sso_amazon/ejluayhfas', to: 'core/webhook/sso/amazon#hook'
  post 'core/webhook/sso_apple/fmmjgdqqmd', to: 'core/webhook/sso/apple#hook'
  # get 'core/webhook/sso_facebook/sooiowfjov', to: 'core/webhook/sso/facebook#hook'
  post 'core/webhook/sso_google/ngcwnmptfx', to: 'core/webhook/sso/google#hook'
  get '/auth/facebook/callback', to: 'core/webhook/sso/facebook#hook'
  get 'single_sign_on', to: 'core/user#single_sign_on'

  get 'account-locked', to: 'core/user#locked'

  get 'reset-password-request', to: 'core/user#reset_passcode_request'
  post 'email-reset-password-link', to: 'core/user#email_reset_passcode_link'
  get 'reset-password-request-confirmation', to: 'core/user#reset_passcode_request_confirmation'
  get 'reset-password', to: 'core/user#reset_passcode_show'
  post 'reset-password', to: 'core/user#reset_passcode'

  get 'profile', to: 'core/user#profile_show'
  get 'profile-email-address', to: 'core/user#profile_email_address_show'
  get 'profile-password', to: 'core/user#profile_passcode_show'
  post 'update-profile', to: 'core/user#update_profile'
  post 'update-profile-email-address', to: 'core/user#update_profile_email_address'
  post 'update-profile-passcode', to: 'core/user#update_profile_passcode'

  get 'delete-account', to: 'core/user#delete_account_show'
  post 'delete-account', to: 'core/user#delete_account'
  get 'delete-account-confirmation', to: 'core/user#delete_account_confirmation'

  get 'sign-out', to: 'core/user#sign_out'

  # ----------------------

  get 'account', to: 'user#show'

  get 'add-credit-card', to: 'core/user#add_credit_card_show'
  post 'add-credit-card', to: 'core/user#add_credit_card'
  get 'delete-credit-card', to: 'core/user#delete_credit_card'

  get 'add-shipping-address', to: 'core/user#add_shipping_address_show'
  post 'add-shipping-address', to: 'core/user#add_shipping_address'
  get 'delete-shipping-address', to: 'core/user#delete_shipping_address'

  # ----------------------------------------------------------------------------

  get 'contact-us', to: 'home#contact_us'

  # ----------------------------------------------------------------------------

  get 'sign-up/site-live', to: 'core/site_alert#site_live'

  post 'site-alert-sign-up', to: 'core/site_alert#sign_up'
  get 'site-alert-sign-up-confirmation', to: 'core/site_alert#sign_up_confirmation'

  # ----------------------------------------------------------------------------

  get 'newsletter', to: 'core/newsletter#sign_up_show'
  post 'newsletter-sign-up', to: 'core/newsletter#sign_up'

  get 'newsletter-sign-up-confirmation', to: 'core/newsletter#sign_up_confirmation'

  # ---------------------------------------------------------------------------- shopping cart

  get 'shopping-cart', to: 'core/shopping_cart#index'

  # ----------------------------------------------------------------------------

end