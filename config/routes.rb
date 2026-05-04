HawthorneCore::Engine.routes.draw do

  # ---------------------------------------------------------------------------- Account

  # sign-in
  get 'sign-in', to: 'user/session#sign_in_show'
  post 'sign-in', to: 'user/session#sign_in'

  # sign-in code
  get 'verify-sign-in-code', to: 'user/session#verify_code_show'
  get 'verify-sign-in-code-via-magic-link', to: 'user/session#verify_code',  defaults: { code_delivery_method: HawthorneCore::User::CODE_VIA_EMAIL, from_magic_link: true }
  post 'verify-sign-in-code', to: 'user/session#verify_code'
  get 'resend-sign-in-code', to: 'user/session#resend_code'
  get 'resend-sign-in-code-via-email', to: 'user/session#resend_code_via_email'
  get 'resend-sign-in-code-via-text', to: 'user/session#resend_code_via_phone'

  # sign-out
  get 'sign-out', to: 'user/session#sign_out'

  # account home
  get 'account', to: redirect('account/profile')

  # ---------------------- Profile

  # home
  get 'account/profile', to: 'user/profile#show'

  # name
  get 'account/profile/name', to: 'user/profile/name#show'
  post 'account/profile/name', to: 'user/profile/name#update'

  # email
  get 'account/profile/email', to: 'user/profile/email#show'
  post 'account/profile/verify-email', to: 'user/profile/email#verify'
  get 'account/profile/verify-email-code', to: 'user/profile/email#verify_code_show'
  post 'account/profile/verify-email-code', to: 'user/profile/email#verify_code'
  get 'account/profile/resend-email-code', to: 'user/profile/email#resend_code'

  # phone number
  get 'account/profile/phone-number', to: 'user/profile/phone_number#show'
  post 'account/profile/verify-phone-number', to: 'user/profile/phone_number#verify'
  get 'account/profile/verify-phone-number-code', to: 'user/profile/phone_number#verify_code_show'
  post 'account/profile/verify-phone-number-code', to: 'user/profile/phone_number#verify_code'
  get 'account/profile/resend-phone-number-code', to: 'user/profile/phone_number#resend_code'
  delete 'account/profile/remove-phone-number', to: 'user/profile/phone_number#delete'

  # sign-in code default delivery
  get 'account/profile/sign-in-code-default-delivery', to: 'user/profile/sign_in_code_default_delivery#show'
  post 'account/profile/sign-in-code-default-delivery', to: 'user/profile/sign_in_code_default_delivery#update'

  # delete account
  get 'account/profile/delete-account', to: 'user/profile/delete_account#show'
  post 'account/profile/delete-account-verify', to: 'user/profile/delete_account#verify'
  get 'account/profile/delete-account-verify-code', to: 'user/profile/delete_account#verify_code_show'
  post 'account/profile/delete-account-verify-code', to: 'user/profile/delete_account#verify_code'
  get 'account/profile/delete-account-resend-code', to: 'user/profile/delete_account#resend_code'
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

  # ---------------------- Favorites

  get 'account/gift_cards', to: 'user/gift_cards#show'

  # ---------------------- Notifications

  get 'account/notifications', to: 'user/notifications#show'

  # ---------------------- Orders

  get 'account/orders', to: 'user/orders#show'

  # ---------------------- Payment Methods (Credit Cards)

  get 'account/payment-methods', to: 'user/payment_methods#index'
  get 'account/new-payment-method', to: 'user/payment_methods#new'
  post 'account/add-payment-method', to: 'user/payment_methods#create'
  delete 'account/profile/delete-payment-method', to: 'user/payment_methods#delete'
  patch 'account/profile/set-default-payment-method', to: 'user/payment_methods#set_default'

  # ----------------------------------------------------------------------------

end