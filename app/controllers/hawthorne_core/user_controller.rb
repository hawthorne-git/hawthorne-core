# v3.0XXX

class HawthorneCore::UserController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?

  # ----------------------------------------------------------------------------- Show (Account)

  # show the users account
  def show

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :email_address, :phone_number, :sign_in_pin_default_delivery).
      find_by(user_id: session[:user_id])

    # find the users shipping addresses
    @shipping_addresses = HawthorneCore::UserShippingAddress.
      select(:token, :street_address, :street_address_extended, :city, :state_province, :postal_code, :country_code_alpha2).
      active.
      order(created_at: :desc)

    # ----------------------

    @html_title = 'My Account'

  end

  # -----------------------------------------------------------------------------

end