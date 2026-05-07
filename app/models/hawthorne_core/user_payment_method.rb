# v3.0

class HawthorneCore::UserPaymentMethod < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::UserPaymentMethod::Stripe


  # -----------------------------------------------------------------------------

  self.table_name = 'user_payment_methods'

  def id = user_payment_method_id

  # -----------------------------------------------------------------------------

  def default? = default

  # -----------------------------------------------------------------------------

  # as stripe is our merchant, set the payment method id to the stripes payment method id
  def payment_method_id = stripe_payment_method_id

  # -----------------------------------------------------------------------------

  # determine if a credit card is active
  def self.credit_card_active?(expiration_month, expiration_year) = !credit_card_expired?(expiration_month, expiration_year)

  # determine if a credit card is expired
  def self.credit_card_expired?(expiration_month, expiration_year) = Date.new(expiration_year, expiration_month, 1).end_of_month < Date.current

  # -----------------------------------------------------------------------------

  # get the number of active credit cards for a user
  def self.nbr_active_credit_cards(user_id) = active.where(user_id:, payment_method_type: 'CREDIT_CARD').count

  # determine if the user has exactly one active credit card
  def self.one_active_credit_card?(user_id) = (nbr_active_credit_cards(user_id) == 1)

  def self.only_active_credit_card(user_id) = one_active_credit_card?(user_id) ? active.where(user_id:).first : nil

  # -----------------------------------------------------------------------------

  # determine if the user has a defaulted payment method
  def self.defaulted_payment_method_exists?(user_id) = active.exists?(user_id:, default: true)

  # set all the user payment methods as not defaulted
  def self.set_all_payment_methods_as_not_defaulted(user_id:) = where(user_id:).update_all(default: false)

  # -----------------------------------------------------------------------------

  # clean up a users defaulted payment methods
  # if the user has more than 1 defaulted - which should not happen, set all as not defaulted
  def self.clean_defaulted(user_id:)
    return if where(user_id:, default: true).count <= 1
    where(user_id:).update_all(default: false)
  end

  # -----------------------------------------------------------------------------

  # find the payment method, by its token
  def self.find_by_token_with_user_id(user_id:, token:) = active.find_by(user_id:, token:)

  # -----------------------------------------------------------------------------

  # (soft) delete the payment method
  # detach the payment method within stripe
  def perform_delete
    HawthorneCore::Services::StripeSvc.detach_payment_method(user_id:, payment_method_id:)
    soft_delete
    HawthorneCore::UserAction::Log.remove_credit_card(note: { token: token })

    # ----------------------

    # if this user has one active credit card - set this card as the default
    #if user.one_active_credit_card?
    #  payment_method_to_default = HawthorneCore::UserPaymentMethod.active.where(user_id:).first
    #  payment_method_to_default.update_columns(default: true)
    #end

  end

  # -----------------------------------------------------------------------------

end