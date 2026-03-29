# v3.0

module HawthorneCore::Helpers::PhoneNumber

  # -----------------------------------------------------------------------------

  # determine if the two phone numbers match
  def self.match?(phone_number_a, phone_number_b) = Phonelib.parse(phone_number_a, 'US').e164 == Phonelib.parse(phone_number_b, 'US').e164

  # -----------------------------------------------------------------------------

  # format a US phone number
  # ex: given '18458024726', return '1 (845) 802-4726'
  def self.us_format(phone_number)
    digits = phone_number.to_s.gsub(/\D/, '')
    return phone_number if digits.length != 11 || digits[0] != '1'
    "#{digits[0]} (#{digits[1,3]}) #{digits[4,3]}-#{digits[7,4]}"
  end

  # -----------------------------------------------------------------------------

  # determine if a US phone number syntax is valid
  def self.us_syntax_valid?(phone_number)
    digits = phone_number.to_s.gsub(/\D/, '')
    digits = digits[1..] if digits.length == 11 && digits.start_with?('1')
    digits.length == 10
  end

  # -----------------------------------------------------------------------------

end