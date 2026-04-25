HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  # sign-in
  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  # sign-in pin
  get 'verify-sign-in-pin', to: 'user/session#verify_sign_in_pin_show'
  get 'verify-sign-in-pin-via-magic-link', to: 'user/session#verify_sign_in_pin',  defaults: { pin_delivery_method: HawthorneCore::User::PIN_VIA_EMAIL, from_magic_link: true }
  post 'verify-sign-in-pin', to: 'user/session#verify_sign_in_pin'
  get 'resend-sign-in-pin', to: 'user/session#resend_sign_in_pin'
  get 'resend-sign-in-pin-via-email', to: 'user/session#resend_sign_in_pin_via_email'
  get 'resend-sign-in-pin-via-text', to: 'user/session#resend_sign_in_pin_via_phone'

  # sign-out
  get 'sign-out', to: 'user/session#sign_out'

  # account home
  get 'account', to: redirect('account/profile')

  # ---------------------- Profile

  # home
  get 'account/profile', to: 'user/profile#show'

  # name
  get 'account/profile/full-name', to: 'user/profile#full_name_show'
  post 'account/profile/full-name', to: 'user/profile#full_name_update'

  # email address
  get 'account/profile/email-address', to: 'user/profile/email_address#show'
  post 'account/profile/email-address-verify', to: 'user/profile/email_address#verify'
  get 'account/profile/email-address-verify-pin', to: 'user/profile/email_address#verify_pin_show'
  post 'account/profile/email-address-verify-pin', to: 'user/profile/email_address#verify_pin'
  get 'account/profile/email-address-resend-pin', to: 'user/profile/email_address#resend_pin'

  # phone number
  get 'account/profile/phone-number', to: 'user/profile/phone_number#show'
  post 'account/profile/phone-number-verify', to: 'user/profile/phone_number#verify'
  get 'account/profile/phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin_show'
  post 'account/profile/phone-number-verify-pin', to: 'user/profile/phone_number#verify_pin'
  get 'account/profile/phone-number-resend-pin', to: 'user/profile/phone_number#resend_pin'
  delete 'account/profile/remove-phone-number', to: 'user/profile/phone_number#delete'

  # sign-in pin default delivery
  get 'account/profile/sign-in-pin-default-delivery', to: 'user/profile#sign_in_pin_default_delivery_show'
  post 'account/profile/sign-in-pin-default-delivery', to: 'user/profile#sign_in_pin_default_delivery_update'

  # delete account
  get 'account/profile/delete-account', to: 'user/profile/delete_account#show'
  post 'account/profile/delete-account-verify', to: 'user/profile/delete_account#verify'
  get 'account/profile/delete-account-verify-pin', to: 'user/profile/delete_account#verify_pin_show'
  post 'account/profile/delete-account-verify-pin', to: 'user/profile/delete_account#verify_pin'
  get 'account/profile/delete-account-resend-pin', to: 'user/profile/delete_account#resend_pin'
  get 'account-deleted', to: 'home#account_deleted'

  # ---------------------- Addresses

  get 'account/addresses', to: 'user/addresses#index'
  get 'account/new-address', to: 'user/addresses#new'
  post 'account/new-address-with-selected-country', to: 'user/addresses#new_selected_country'
  post 'account/add-address', to: 'user/addresses#create'
  get 'account/edit-address', to: 'user/addresses#edit'
  patch 'account/update-address', to: 'user/addresses#update'
  delete 'account/remove-address', to: 'user/addresses#delete'

  # ---------------------- Favorites

  get 'account/favorites', to: 'user/favorites#show'

  # ---------------------- Notifications

  get 'account/notifications', to: 'user/notifications#show'

  # ---------------------- Orders

  get 'account/orders', to: 'user/orders#show'

  # ---------------------- Payments

  get 'account/payments', to: 'user/payments#index'
  get 'account/new-payment', to: 'user/payments#new'
  post 'account/add-payment', to: 'user/payments#create'
  delete 'account/profile/delete-payment', to: 'user/payments#delete'
  patch 'account/profile/set-default-payment', to: 'user/payments#set_default'

  # ----------------------------------------------------------------------------

end