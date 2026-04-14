# v3.0

class HawthorneCore::User::Profile::ShippingAddressController < HawthorneCore::AccountApplicationController

  # -----------------------------------------------------------------------------

  def index

    # ----------------------

    # find the users shipping addresses
    @shipping_addresses = HawthorneCore::UserShippingAddress.
      select(:token, :full_name, :street_address, :street_address_extended, :city, :state_province, :postal_code, :country_code_alpha2, :phone_number).
      active.
      where(user_id: session[:user_id])

    # ----------------------

    # if the user does not have any shipping addresses in their profile,
    # redirect the user to add their first shipping address
    redirect_to account_profile_add_shipping_address_path unless @shipping_addresses.any?

    # ----------------------

    @html_title = 'Shipping Addresses | My Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page to add a shipping address
  # by default the page is loaded with the Cloudflare country selected
  # if the Cloudflare country is NOT a country that we ship to - force the user to select a country
  # the user can also choose to select an alternate country - if selected, use this country
  def new

    # get the request attributes
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

    # ----------------------

    # find the selected country ... if present
    if selected_country_code_alpha2.present?
      @selected_country = HawthorneCore::Country.
        select(:handle, :code_alpha2, :code_alpha3).
        active.
        find_by(code_alpha2: selected_country_code_alpha2.strip.upcase, ship_to: true)
    end

    # ----------------------

    # if a selected country is not present, default to Cloudflare
    unless @selected_country

      # get the users country (code alpha 2) via Cloudflare
      cloudflare_country_code_alpha2 = request.headers['CF-IPCountry']

      # in the unexpected case where the Cloudflare country code is not found within our list, set to US
      unless HawthorneCore::Country.code_alpha2_exists?(cloudflare_country_code_alpha2)
        cloudflare_country_code_alpha2 = 'US'
        HawthorneCore::UserAction::Log.shipping_address_failure(user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Country not found with Cloudflare country code', cloudflare_country_code: cloudflare_country_code_alpha2 }, request.remote_ip, cookies[:user_session_token])
      end

      # if the Cloudflare country is in our list of countries to ship to, set this as the selected country
      # else this will force the user to select a country that we ship to
      if HawthorneCore::Country.ship_to?(cloudflare_country_code_alpha2)
        @selected_country = HawthorneCore::Country.
          select(:handle, :code_alpha2, :code_alpha3).
          active.
          find_by(code_alpha2: cloudflare_country_code_alpha2.strip.upcase, ship_to: true)
      end

    end

    # ----------------------

    # get all countries that we ship to
    # and get all states that we ship to if the selected country is US
    @ship_to_countries = HawthorneCore::Country.ship_to
    @us_states = HawthorneCore::UsState.ship_to if @selected_country&.us?

    # ----------------------

    @html_title = 'Add Shipping Address | My Profile'

  end

  # -----------------------------------------------------------------------------

  # user action when a country is selected - on adding
  def new_selected_country = redirect_to account_profile_add_shipping_address_path(selected_country: params[:country_code_alpha2])

  # -----------------------------------------------------------------------------

  # action to create the shipping address
  def create

    # ----------------------

    # get the request attributes, and merge in the user id - needed to create the record
    attrs = normalized_address_params
    attrs = attrs.merge(user_id: session[:user_id])

    # ----------------------

    # TODO: verify, and if not verified ... different action?

    # ----------------------

    # if the shipping address matches a current,
    # log it, and display an error message
    if HawthorneCore::UserShippingAddress.identical?(attrs)
      HawthorneCore::UserAction::Log.shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.shipping_address_identical, { action: 'CREATE', attrs: attrs }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/shipping_address_failed', locals: { shipping_address_identical: true }) and return
    end

    # ----------------------

    # add the users shipping address - log it
    shipping_address = HawthorneCore::UserShippingAddress.create!(attrs)
    HawthorneCore::UserAction::Log.add_shipping_address(session[:user_id], attrs.merge(user_shipping_address_id: shipping_address.id), request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their shipping addresses
    redirect_to account_profile_shipping_addresses_path

  end

  # -----------------------------------------------------------------------------

  def edit

    # get the request attributes
    token = params[:token]

    # ----------------------

    # find the users shipping address to edit
    @shipping_address = HawthorneCore::UserShippingAddress.
      select(:token, :full_name, :street_address, :street_address_extended, :city, :state_province, :postal_code, :country_code_alpha2, :phone_number).
      active.
      find_by(user_id: session[:user_id], token: token)

    # in the unexpected case where the users shipping address is not found
    # log it, and redirect the user to view their shipping addresses
    unless @shipping_address
      HawthorneCore::UserAction::Log.shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Users shipping address not found', token: token }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_profile_shipping_addresses_path and return
    end

    # ----------------------

    # get the selected country within the shipping address
    @selected_country = HawthorneCore::Country.
      select(:handle, :code_alpha2, :code_alpha3).
      active.
      find_by(code_alpha2: @shipping_address.country_code_alpha2, ship_to: true)

    # ----------------------

    # get all states that we ship to if the selected country is US
    @us_states = HawthorneCore::UsState.ship_to if @selected_country&.us?

    # ----------------------

    @html_title = 'Update Shipping Address | My Profile'

  end

  # -----------------------------------------------------------------------------

  def update

    # ----------------------

    # get the request attributes
    attrs = normalized_address_params

    # ----------------------

    # find the users shipping address to update
    shipping_address = HawthorneCore::UserShippingAddress.
      select(:user_shipping_address_id).
      active.
      find_by(user_id: session[:user_id], token: attrs[:token])

    # in the unexpected case where the users shipping address is not found
    # log it, and redirect the user to view their shipping addresses
    unless shipping_address
      HawthorneCore::UserAction::Log.shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Users shipping address not found', token: attrs[:token] }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_profile_shipping_addresses_path and return
    end

    # ----------------------

    # TODO: verify, and if not verified ... different action?

    # ----------------------

    # if the shipping address matches a current,
    # log it, and display an error message
    if HawthorneCore::UserShippingAddress.identical?(attrs)
      HawthorneCore::UserAction::Log.shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.shipping_address_identical, { action: 'UPDATE', attrs: attrs }, request.remote_ip, cookies[:user_session_token])
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/shipping_address_failed', locals: { shipping_address_identical: true }) and return
    end

    # ----------------------

    # update the users shipping address - log it
    shipping_address.update!(attrs)
    HawthorneCore::UserAction::Log.update_shipping_address(session[:user_id], attrs.merge(user_shipping_address_id: shipping_address.id), request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their shipping addresses
    redirect_to account_profile_shipping_addresses_path

  end

  # -----------------------------------------------------------------------------

  def delete

    # get the request attributes
    token = params[:token]

    # ----------------------

    # find the users shipping address to soft delete
    shipping_address = HawthorneCore::UserShippingAddress.
      select(:user_shipping_address_id, :user_id, :deleted).
      find_by(user_id: session[:user_id], token: token)

    # in the unexpected case where the users shipping address is not found
    # log it, and redirect the user to view their shipping addresses
    unless shipping_address
      HawthorneCore::UserAction::Log.shipping_address_failure(session[:user_id], HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Users shipping address not found', token: token }, request.remote_ip, cookies[:user_session_token])
      redirect_to account_profile_shipping_addresses_path and return
    end

    # soft delete the record
    shipping_address.soft_delete

    # log it
    HawthorneCore::UserAction::Log.remove_shipping_address(shipping_address.user_id, { user_shipping_address_id: shipping_address.id }, request.remote_ip, cookies[:user_session_token])

    # ----------------------

    # redirect the user to view their shipping addresses
    redirect_to account_profile_shipping_addresses_path

  end

  # -----------------------------------------------------------------------------

  private

  def address_params
    params.require(:user_shipping_address).
      permit(
        :token,
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

  def normalized_address_params
    {
      token: address_params[:token],
      full_name: address_params[:full_name].to_s.strip.squish,
      street_address: address_params[:street_address].to_s.strip.squish,
      street_address_extended: address_params[:street_address_extended].to_s.strip.squish,
      city: address_params[:city].to_s.strip.squish,
      state_province: address_params[:state_province].to_s.strip.squish,
      postal_code: address_params[:postal_code].to_s.strip.squish.upcase,
      country_code_alpha2: address_params[:country_code_alpha2].to_s.strip.squish.upcase,
      phone_number: address_params[:phone_number].to_s.strip.squish.upcase
    }
  end

  # -----------------------------------------------------------------------------

end