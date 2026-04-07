# v3.0

class HawthorneCore::User::Profile::ShippingAddressController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in prior to all actions
  before_action :verify_signed_in?

  # -----------------------------------------------------------------------------

  # show the page to add a shipping address
  # by default the page is loaded with the Cloudflare country selected
  # if the Cloudflare country is NOT a country that we ship to - force the user to select a country
  # the user can also choose to select an alternate country - if selected, use this country
  def new

    # get the page attributes
    @select_country = (params[:select_country] == 'true')
    selected_country_code_alpha2 = params[:selected_country]

    # ----------------------

    # find the user
    user = HawthorneCore::User.
      select(:user_id, :full_name, :phone_number).
      find_by(user_id: session[:user_id])

    # set the users shipping address defaults ... add in their name / phone number
    @shipping_address = HawthorneCore::UserShippingAddress.new
    @shipping_address.full_name = user.full_name
    @shipping_address.phone_number = HawthorneCore::Helpers::PhoneNumber.us_format(user.phone_number)

    # find the selected country ... if present
    if selected_country_code_alpha2.present?
      @selected_country = HawthorneCore::Country.
        select(:handle, :code_alpha2, :code_alpha3).
        active.
        find_by(code_alpha2: selected_country_code_alpha2.strip.upcase, ship_to: true)
    end

    # ----------------------

    # if the action is to NOT select a country and the user did NOT select a country ...
    # get the selected country via Cloudflare
    if !@select_country && !@selected_country

      # get the users country (code alpha 2) via Cloudflare
      cloudflare_country_code_alpha2 = request.headers['CF-IPCountry']

      # in the unexpected case where the Cloudflare country code is not found within our list, set to US
      unless HawthorneCore::Country.code_alpha2_exists?(cloudflare_country_code_alpha2)
        cloudflare_country_code_alpha2 = 'US'
        HawthorneCore::UserAction::Log.shipping_address_failure(user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Country not found with Cloudflare country code', cloudflare_country_code: cloudflare_country_code_alpha2 }, request.remote_ip, cookies[:user_session_token])
      end

      # if the Cloudflare country is in our list of countries to ship to, set this as the selected country
      # else force the user to select a country
      if HawthorneCore::Country.ship_to?(cloudflare_country_code_alpha2)
        @selected_country = HawthorneCore::Country.
          select(:handle, :code_alpha2, :code_alpha3).
          active.
          find_by(code_alpha2: cloudflare_country_code_alpha2.strip.upcase, ship_to: true)
      else
        @select_country = true
      end

    end

    # ----------------------

    # if the user is to select a country
    # this is either because they choose to, or their Cloudflare country code is a country we do not ship to
    # find all countries that we ship to
    if @select_country
      @ship_to_countries = HawthorneCore::Country.
        select(:handle, :code_alpha2).
        active.
        where(ship_to: true).
        order(handle: :asc)
    end

    # ----------------------

    # if the selected country is US ...
    # find all us states that we ship to
    if @selected_country&.us?
      @us_states = HawthorneCore::UsState.
        select(:handle, :code_alpha2).
        active.
        where(ship_to: true).
        order(handle: :asc)
    end

    # ----------------------

    @html_title = 'Shipping Address | My Account'
    @breadcrumbs = [
      { title: 'My Account', link: account_path },
      { title: 'Shipping Address', link: nil }
    ]

  end

  # -----------------------------------------------------------------------------

  # user action that they want to select a country to ship to
  def new_select_country = redirect_to account_profile_add_shipping_address_path(select_country: true)

  # user action when a country is selected
  def new_selected_country = redirect_to account_profile_add_shipping_address_path(selected_country: params[:country_code_alpha2])

  # -----------------------------------------------------------------------------

  # action to create the shipping address
  def create

    # ----------------------

    # get the form attributes, and merge in the user id - needed to create the record
    attrs = address_params
    attrs = attrs.merge(user_id: session[:user_id])

    # ----------------------

    # TODO: verify, and if not verified ... different action?

    # ----------------------

    # add the users shipping address - log it
    shipping_address = HawthorneCore::UserShippingAddress.create!(attrs)
    HawthorneCore::UserAction::Log.add_shipping_address(session[:user_id], attrs.merge(user_shipping_address_id: shipping_address.id), request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  def delete

    # get the page attributes
    token = params[:token]

    # ----------------------

    # find the users shipping address to soft delete
    shipping_address = HawthorneCore::UserShippingAddress.
      select(:user_shipping_address_id, :user_id, :deleted).
      find_by(user_id: session[:user_id], token: token)

    # in the unexpected case where the users shipping address is not found
    # log it, and redirect the user to view their account
    unless shipping_address
      HawthorneCore::UserAction::Log.remove_shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Users shipping address not found', user_id: session[:user_id], token: token }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_path and return
    end

    # soft delete the record
    shipping_address.soft_delete

    # log it
    HawthorneCore::UserAction::Log.remove_shipping_address(shipping_address.user_id, { user_shipping_address_id: shipping_address.id }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their account
    redirect_to account_path

  end

  # -----------------------------------------------------------------------------

  private

  def address_params
    params.require(:user_shipping_address).
      permit(
        :full_name,
        :street_address,
        :street_address_extended,
        :city,
        :state_province,
        :postal_code,
        :country_code_alpha2,
        :phone_number
      )
  end

  # -----------------------------------------------------------------------------

end