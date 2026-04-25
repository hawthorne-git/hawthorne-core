# v3.0

module HawthorneCore::Helpers::PhoneNumber

  # -----------------------------------------------------------------------------

  # determine if the two phone numbers match
  def self.match?(phone_number:, phone_number_to_match:) = Phonelib.parse(phone_number, 'US').e164 == Phonelib.parse(phone_number_to_match, 'US').e164

  # -----------------------------------------------------------------------------

  # mask a phone number
  # ex: convert '+1 845-802-4726' to '••• ••• 4726'
  # ex: convert '+44 845-802-4726' to '+44 ••• ••• 4726'
  def self.masked(phone_number:)

    # parse the phone number
    # return if the phone number is not parsed
    phone_parsed = Phonelib.parse(phone_number)
    return nil unless phone_parsed.valid?

    # get the country + digits from the parsed phone number
    # ex: '+1 845-802-4726', country = 1, digits = 18458024726
    country = phone_parsed.country_code
    digits = phone_parsed.e164.gsub(/\D/, '')

    # mask the phone number
    # note that US phone numbers are masked differently, the country digit is NOT included
    digits_last4 = digits[-4, 4]
    phone_parsed.country == 'US' ? "••• ••• #{digits_last4}" : "+#{country} ••• ••• #{digits_last4}"

  end

  # -----------------------------------------------------------------------------

  # format a US phone number
  # ex: given '18458024726', return '1 (845) 802-4726'
  def self.us_format(phone_number:)
    digits = phone_number.to_s.gsub(/\D/, '')
    return phone_number if digits.length != 11 || digits[0] != '1'
    "#{digits[0]} (#{digits[1,3]}) #{digits[4,3]}-#{digits[7,4]}"
  end

  # -----------------------------------------------------------------------------

  # determine if a US phone number syntax is valid
  def self.us_syntax_valid?(phone_number:)
    digits = phone_number.to_s.gsub(/\D/, '')
    digits = digits[1..] if digits.length == 11 && digits.start_with?('1')
    digits.length == 10
  end

  # -----------------------------------------------------------------------------

end