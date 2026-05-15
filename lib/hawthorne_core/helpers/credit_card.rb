module HawthorneCore::Helpers::CreditCard

  # -----------------------------------------------------------------------------

  # determine if a credit card is expired
  def self.credit_card_expired?(exp_month:, exp_year:) = Date.new(exp_year, exp_month, 1).end_of_month < Date.current

  # -----------------------------------------------------------------------------

end