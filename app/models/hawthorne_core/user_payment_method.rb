# v3.0

class HawthorneCore::UserPaymentMethod < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # -----------------------------------------------------------------------------

  self.table_name = 'user_payment_methods'

  def id = user_payment_method_id

  # -----------------------------------------------------------------------------

  # determine if a credit card is active
  def self.credit_card_active?(expiration_month, expiration_year) = !credit_card_expired?(expiration_month, expiration_year)

  # determine if a credit card is expired
  def self.credit_card_expired?(expiration_month, expiration_year) = Date.new(expiration_year, expiration_month, 1).end_of_month < Date.current

  # -----------------------------------------------------------------------------

  # determine if the user has a defaulted payment method
  def self.defaulted_payment_method_exists?(user_id) = active.exists?(user_id: user_id, default: true)

  # -----------------------------------------------------------------------------

end