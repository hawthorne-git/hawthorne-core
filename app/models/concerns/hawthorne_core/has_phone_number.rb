# v3.0

module HawthorneCore::HasPhoneNumber
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # mask a phone number
    # ex: convert '+1 845-802-4726' to '••• ••• 4726'
    # ex: convert '+44 845-802-4726' to '+44 ••• ••• 4726'
    def phone_number_masked

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

    # ---------------------------------------------------------------------------------

  end

end