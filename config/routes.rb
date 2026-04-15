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

  get 'account', to: redirect('account/profile')

  # ----------------------

  get 'account/profile', to: 'user/profile#show'

  get 'account/profile/full-name', to: 'user/profile#full_name_show'
  post 'account/profile/full-name', to: 'user/profile#full_name_update'

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

  get 'account/profile/sign-in-pin-default-delivery', to: 'user/profile#sign_in_pin_default_delivery_show'
  post 'account/profile/sign-in-pin-default-delivery', to: 'user/profile#sign_in_pin_default_delivery_update'

  get 'account/profile/shipping-addresses', to: 'user/profile/shipping_address#index'
  get 'account/profile/new-shipping-address', to: 'user/profile/shipping_address#new'
  post 'account/profile/new-shipping-address-with-selected-country', to: 'user/profile/shipping_address#new_selected_country'
  post 'account/profile/add-shipping-address', to: 'user/profile/shipping_address#create'
  get 'account/profile/edit-shipping-address', to: 'user/profile/shipping_address#edit'
  patch 'account/profile/update-shipping-address', to: 'user/profile/shipping_address#update'
  delete 'account/profile/remove-shipping-address', to: 'user/profile/shipping_address#delete'

  get 'account/profile/delete-account', to: 'user/profile/delete_account#show'
  post 'account/profile/delete-account-verify', to: 'user/profile/delete_account#verify'
  get 'account/profile/delete-account-verify-pin', to: 'user/profile/delete_account#verify_pin_show'
  post 'account/profile/delete-account-verify-pin', to: 'user/profile/delete_account#verify_pin'
  get 'account/profile/delete-account-resend-pin', to: 'user/profile/delete_account#resend_pin'
  get 'account-deleted', to: 'home#account_deleted'

  # ----------------------

  get 'sign-out', to: 'user/session#sign_out'

  # ----------------------------------------------------------------------------

end