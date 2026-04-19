# v3.0

class HawthorneCore::UserPaymentMethod < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # -----------------------------------------------------------------------------

  self.table_name = 'user_payment_methods'

  def id = user_payment_method_id

  # -----------------------------------------------------------------------------

  def default? = default

  # -----------------------------------------------------------------------------

  # determine if a credit card is active
  def self.credit_card_active?(expiration_month, expiration_year) = !credit_card_expired?(expiration_month, expiration_year)

  # determine if a credit card is expired
  def self.credit_card_expired?(expiration_month, expiration_year) = Date.new(expiration_year, expiration_month, 1).end_of_month < Date.current

  # -----------------------------------------------------------------------------

  # get the number of active credit cards for a user
  def self.nbr_active_credit_cards(user_id) = active.where(user_id: user_id).count

  # determine if the user has exactly one active credit card
  def self.one_active_credit_card?(user_id) = (nbr_active_credit_cards(user_id) == 1)

  # -----------------------------------------------------------------------------

  # determine if the user has a defaulted payment method
  def self.defaulted_payment_method_exists?(user_id) = active.exists?(user_id: user_id, default: true)

  # set all the user payment methods to not be defaulted
  def self.set_all_payment_methods_to_not_defaulted(user_id) = where(user_id: user_id).update_all(default: false)

  # -----------------------------------------------------------------------------

  # clean up a users defaulted payment methods
  # if the user has more than 1 defaulted - which should not happen, set all as not defaulted
  def self.clean_defaulted(user_id)
    return if where(user_id: user_id, default: true).count <= 1
    where(user_id: user_id).update_all(default: false)
  end

  # -----------------------------------------------------------------------------

  # find the users active stripe credit cards
  # in doing so, clean up
  def self.active_stripe_credit_cards(user_id, stripe_customer_id)

    # clean the users defaulted payment methods, if needed
    clean_defaulted(user_id)

    # find the users active stripe credit card payment methods (in our database)
    payment_methods = select(:user_payment_method_id, :token, :stripe_payment_method_id, :default).
      active.
      where(user_id: user_id, payment_method_type: 'CREDIT_CARD').
      where.not(stripe_payment_method_id: nil)

    # find the users credit cards (in stripe)
    credit_cards = HawthorneCore::Services::StripeSvc.find_all_customer_credit_cards(user_id, stripe_customer_id)

    # find all active credit cards
    # in the process, if an expired credit card is marked as default - remove it as default
    active_credit_cards = []
    credit_cards.each do |credit_card|
      payment_method = payment_methods.find { |pm| pm.stripe_payment_method_id == credit_card[:stripe_payment_method_id] }
      next unless payment_method.present?
      if HawthorneCore::UserPaymentMethod.credit_card_active?(credit_card[:credit_card_expiration_month], credit_card[:credit_card_expiration_year])
        active_credit_cards.push(credit_card.merge(token: payment_method.token, default: payment_method.default))
      else
        payment_method.update_columns(default: false) if payment_method.default?
      end
    end

    # return all active credit cards
    return active_credit_cards

  end

  # -----------------------------------------------------------------------------

end