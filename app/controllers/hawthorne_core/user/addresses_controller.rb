class HawthorneCore::User::AddressesController < HawthorneCore::AccountApplicationController

  include HawthorneCore::Validation::Address

  # -----------------------------------------------------------------------------

  # show the user addresses
  def index

    # find the users addresses
    @addresses = HawthorneCore::UserAddress.all_for_user(user_id:)

    @html_title = 'Addresses | Profile'

  end

  # -----------------------------------------------------------------------------

  # show the page to add an address
  # by default the page is loaded with the Cloudflare country selected
  # if the Cloudflare country is NOT a country that we ship to - force the user to select a country
  # the user can also choose to select an alternate country - if selected, use this country
  def new

    code_alpha2 = params[:selected_country]&.strip&.upcase

    # find the users name and phone number
    name, phone_number = HawthorneCore::User.where(user_id:).pick(:name, :phone_number)

    # set the address defaults ... add in the users name / phone number
    @address = HawthorneCore::UserAddress.new
    @address.name = name
    @address.phone_number = HawthorneCore::Helpers::PhoneNumber.us_format(phone_number:)

    # find the selected country (by the user)
    @selected_country = HawthorneCore::Country.ship_to_country_with_code_alpha2(code_alpha2:)

    # if a selected country is not present, default to cloudflare
    unless @selected_country

      # get the users country (code alpha 2) via cloudflare
      # if the cloudflare country code is not found, default to US
      code_alpha2 = request.headers['CF-IPCountry']&.strip&.upcase
      unless HawthorneCore::Country.code_alpha2_exists?(code_alpha2:)
        HawthorneCore::UserAction::Log.address_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: 'HawthorneCore::User::AddressesController', method: 'new', message: 'Country (code alpha 2) not found with Cloudflare country code', code_alpha2: })
        code_alpha2 = 'US'
      end

      # if the cloudflare country is an active country shipped to, set this country as the selected country
      # else this will force the user to select a country that we ship to
      @selected_country = HawthorneCore::Country.ship_to_country_with_code_alpha2(code_alpha2:) if HawthorneCore::Country.ship_to_code_alpha2?(code_alpha2:)

    end

    # find all countries that we ship to,
    # and find all states that we ship to if the selected country is US
    @ship_to_countries = HawthorneCore::Country.ship_to
    @us_states = HawthorneCore::UsState.ship_to if @selected_country&.us?

    @html_title = 'Add Address | Profile'

  end

  # -----------------------------------------------------------------------------

  # action when a user selects an alternate country
  def new_selected_country = redirect_to account_new_address_path(selected_country: params[:country_code_alpha2])

  # -----------------------------------------------------------------------------

  # create am address
  def create

    attrs = normalized_address_params.merge(user_id:)

    # verify the address is not identical to another on file
    return render_identical_address_error(action: 'ADD', attrs:) if HawthorneCore::UserAddress.identical?(attrs)

    # TODO: verify address, and if not verified ... different action before adding?

    # add the address
    address = HawthorneCore::UserAddress.perform_add(attrs:)

    # set as default if requested
    address.set_as_default if params.dig(:user_address, :set_as_default) == '1'

    # redirect the user to view their addresses
    redirect_to account_addresses_path

  end

  # -----------------------------------------------------------------------------

  # show the page to edit an address
  def edit

    token = params[:token]

    # find the address to edit
    # verify the address belongs to the user
    @address = HawthorneCore::UserAddress.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_address_not_found(method: 'edit', token:) unless @address

    # find the selected country within the address
    # and find all states that we ship to if the selected country is US
    @selected_country = HawthorneCore::Country.ship_to_country_with_code_alpha2(code_alpha2: @address.country_code_alpha2)
    @us_states = HawthorneCore::UsState.ship_to if @selected_country&.us?

    @html_title = 'Update Address | Profile'

  end

  # -----------------------------------------------------------------------------

  # update am address
  def update

    attrs = normalized_address_params
    token = attrs[:token]

    # find the address to update
    # verify the address belongs to the user and the updated address is not identical to another on file
    address = HawthorneCore::UserAddress.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_address_not_found(method: 'update', token:) unless address
    return render_identical_address_error(action: 'UPDATE', attrs:) if HawthorneCore::UserAddress.identical?(attrs)

    # TODO: verify address, and if not verified ... different action before updating?

    # update the address
    address.perform_update(attrs:)

    # set as default if requested
    address.set_as_default if params.dig(:user_address, :set_as_default) == '1'

    # redirect the user to view their addresses
    redirect_to account_addresses_path

  end

  # -----------------------------------------------------------------------------

  # set an address as the default
  def set_default

    token = params[:token]

    # find the address to set as default
    # verify the address belongs to the user
    address = HawthorneCore::UserAddress.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_address_not_found(method: 'set_default', token:) unless address

    # set the address as the default
    address.set_as_default

    # redirect the user to view their addresses
    redirect_to account_addresses_path

  end

  # -----------------------------------------------------------------------------

  # delete am address
  def delete

    token = params[:token]

    # find the address to delete
    # verify the address belongs to the user
    address = HawthorneCore::UserAddress.find_by_token_with_user_id(user_id:, token:)
    return redirect_when_address_not_found(method: 'delete', token:) unless address

    # delete the address
    address.perform_delete

    # redirect the user to view their addresses
    redirect_to account_addresses_path

  end

  # -----------------------------------------------------------------------------

  private

  def address_params
    params.require(:user_address).
      permit(
        :token,
        :name,
        :street_address,
        :street_address_extended,
        :city,
        :state_province,
        :postal_code,
        :country_code_alpha2,
        :phone_number,
        :default
      )
  end

  def normalized_address_params
    {
      token: address_params[:token],
      name: address_params[:name].to_s.strip.squish,
      street_address: address_params[:street_address].to_s.strip.squish,
      street_address_extended: address_params[:street_address_extended].to_s.strip.squish,
      city: address_params[:city].to_s.strip.squish,
      state_province: address_params[:state_province].to_s.strip.squish,
      postal_code: address_params[:postal_code].to_s.strip.squish.upcase,
      country_code_alpha2: address_params[:country_code_alpha2].to_s.strip.squish.upcase,
      phone_number: address_params[:phone_number].to_s.strip.squish.upcase,
      default: address_params[:default]
    }
  end

  # -----------------------------------------------------------------------------

end