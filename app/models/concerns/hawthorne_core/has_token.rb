# v3.0

module HawthorneCore::HasToken
  extend ActiveSupport::Concern

  # ---------------------------------------------------------------------------------

  # length of 1: 29 unique values
  # length of 2: 841
  # length of 3: 24,389
  # length of 4: 707,281
  # length of 5: 20,511,149 (20 million)
  # length of 6: 594,823,321 (594 million)
  # length of 7: 17,249,876,309 (17 billion)
  # length of 8: 500,246,412,961 (500 billion)
  # length of 9: 14,507,145,975,869 (14 trillion)
  # length of 10: 420,707,233,300,201 (420 trillion)
  # length of 11: 12,200,509,765,705,800 (12 quadrillion)
  # length of 12: 353,814,783,205,469,000 (353 quadrillion)

  # ---------------------------------------------------------------------------------

  # define the list of characters to use in creating the token
  # note that certain characters have been removed to limit the chance of generating a 'naughty' word
  ALPHABET = 'BCDFGHJKLMNPQRSTVWXYZ23456789'.chars.freeze

  # define the list of token lengths ... by the objects table name
  TOKEN_LENGTHS =
    {
      'users' => 12,
      'user_shipping_addresses' => 12
    }.freeze

  # ---------------------------------------------------------------------------------

  included do

    # ---------------------------------------------------------------------------------

    # before creating a record,
    # set the records token attribute
    before_validation :set_token, on: :create

    # ---------------------------------------------------------------------------------

    private

    # set the token
    # the length of the token is based on the object type (table name)
    def set_token
      token_length = TOKEN_LENGTHS[self.class.table_name]
      self.token = generate_unique_token(token_length)
    end

    # ------------------------

    # generates a (unique) token at a specified length
    # if the token is already in use, generate another
    def generate_unique_token(length)
      loop do
        candidate = Array.new(length) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
        return candidate unless self.class.exists?(token: candidate)
      end
    end

    # ---------------------------------------------------------------------------------

  end

end