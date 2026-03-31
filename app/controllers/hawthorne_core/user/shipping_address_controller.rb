# v3.0

class HawthorneCore::User::ShippingAddressController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed in prior to all actions
  before_action :verify_signed_in?

  # -----------------------------------------------------------------------------

  # show the page to add a shipping address
  def new

    # ----------------------

    # find the user
    @user = HawthorneCore::User.
      select(:user_id, :full_name, :phone_number).
      find_by(user_id: session[:user_id])

    # ----------------------

    @shipping_address = HawthorneCore::UserShippingAddress.new
    @shipping_address.street_address = '73 Hilltop Rd'
    @shipping_address.city = 'Rhinebeck'
    @shipping_address.state_province = 'NY'
    @shipping_address.postal_code = '12572'
    @shipping_address.country = 'US'

    # ----------------------

    @html_title = 'Shipping Address | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Shipping Address', link: nil }
    ]

    # ----------------------

  end

  # -----------------------------------------------------------------------------

  # action to create the shipping address
  def create

    # ----------------------

    # get the form attributes, and merge in the user id - needed to create the record
    attrs = shipping_address_params
    attrs = attrs.merge(user_id: session[:user_id])

    # ----------------------

    # TODO: is verified? ... different action?

    # ----------------------

    # add the users shipping address - log it
    shipping_address = HawthorneCore::UserShippingAddress.create!(attrs)
    HawthorneCore::UserAction::Log.add_shipping_address(session[:user_id], attrs.merge(user_shipping_address_id: shipping_address.id), request.remote_ip, cookies[:user_session_token])

    # ----------------------

  end

  # -----------------------------------------------------------------------------

  private

  def shipping_address_params
    params.require(:user_shipping_address).
        permit(
        :full_name,
        :street_address,
        :street_address_extended,
        :city,
        :state_province,
        :postal_code,
        :country,
        :phone_number
      )
  end

  # -----------------------------------------------------------------------------

end