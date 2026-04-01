# v3.0XXX

class HawthorneCore::Services::SmartySvc

  VERIFY_INTL_ADDRESS = 'VERIFY INTERNATIONAL ADDRESS'.freeze

  VERIFY_US_ADDRESS = 'VERIFY US ADDRESS'.freeze

  # ----------------------------------------------------------------

  # verify a US address
  def self.verify_us_address(street, street2, city, state, zipcode)
    params = verify_us_address_parms(street, street2, city, state, zipcode)
    verify_address(VERIFY_US_ADDRESS, verify_us_address_api_url, params)
  end

  # ----------------------------------------------------------------

  private

  def self.verify_us_address_api_url = URI('https://us-street.api.smarty.com/street-address').freeze

  def self.verify_us_address_parms(street, street2, city, state, zipcode)
    {
      'auth-id' => HawthorneCore::AppConfig.smarty_auth_id,
      'auth-token' => HawthorneCore::AppConfig.smarty_auth_token,
      street: street,
      street2: street2,
      city: city,
      state: state,
      zipcode: zipcode,
      candidates: 3,
      match: 'strict'
    }
  end

  # ----------------------------------------------------------------

  def self.verify_intl_address_api_url = URI('https://international-street.api.smarty.com/verify').freeze

  # ----------------------------------------------------------------

  # verify an address
  def self.verify_address(verify_address_type, api_url, params)

    uri = api_url.dup
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      return {
        success: false,
        status_code: response.code.to_i,
        error: "Smarty error: #{response.code}",
        candidates: []
      }
    end

    body = JSON.parse(response.body)

    {
      success: true,
      status_code: response.code.to_i,
      candidates: body
    }
  rescue => e
    {
      success: false,
      error: e.message,
      candidates: []
    }

  end

  # ----------------------------------------------------------------

end