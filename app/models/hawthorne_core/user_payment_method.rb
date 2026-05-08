# v3.0

class HawthorneCore::UserPaymentMethod < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken,
          HawthorneCore::UserPaymentMethod::Stripe

  # -----------------------------------------------------------------------------

  self.table_name = 'user_payment_methods'

  def id = user_payment_method_id

  # -----------------------------------------------------------------------------

  # determine if a payment method is marked as default
  def default? = default

  # -----------------------------------------------------------------------------

  # as stripe is our merchant, set the payment method id to the stripes payment method id
  def payment_method_id = stripe_payment_method_id

  # -----------------------------------------------------------------------------

  # find the users payment method, by its token
  def self.find_by_token_with_user_id(user_id:, token:) = active.find_by(user_id:, token:)

  # -----------------------------------------------------------------------------

  # determine if the user has any (active) payment methods
  def self.has_payment_method?(user_id:) = active.where(user_id:).exists?

  # determine if the user has a defaulted payment method
  def self.default_exists?(user_id) = active.exists?(user_id:, default: true)

  # determine if the user has more than one (active or inactive) default payment method
  def self.more_than_one_default_payment_method?(user_id:) = where(user_id:, default: true).count > 1

  # determine if the user has no (active) default payment method
  def self.no_default_payment_method?(user_id:) = !active.where(user_id:, default: true).exists?

  # determine if the user has one (active) default payment method
  def self.one_default_payment_method?(user_id:) = where(user_id:, default: true).count == 1

  # set all payment methods as not defaulted
  def self.set_all_payment_methods_as_not_defaulted(user_id:) = where(user_id:).update_all(default: false)

  # set the payment method last used at checkout / created at, as the default
  # return the token of the payment method set as default
  def self.set_last_used_or_created_as_default(user_id:)
    payment_method = active.where(user_id:).order(Arel.sql("last_checkout_selected_at DESC NULLS LAST"), created_at: :desc).first
    payment_method&.update_columns(default: true)
    payment_method.token
  end

  # -----------------------------------------------------------------------------

  # clean up a users defaulted payment methods
  # exit if the user does not have any (active) payment methods
  # if the user has more than one (active or inactive) payment method defaulted - which should not happen, set all as not defaulted
  # if the user has no (active) payment method defaulted - which can happen when a defaulted card is expired, set all as not defaulted
  # return if the user has one (active) payment method defaulted - this is the expected scenario
  # if there is NOT a payment method defaulted, set the payment method last used at checkout / last created as the default
  # lastly, return is if there was a change
  def self.clean_defaulted(user_id:)
    return { change_made: false } unless has_payment_method?(user_id:)
    set_all_payment_methods_as_not_defaulted(user_id:) if more_than_one_default_payment_method?(user_id:)
    set_all_payment_methods_as_not_defaulted(user_id:) if no_default_payment_method?(user_id:)
    return { change_made: false } if one_default_payment_method?(user_id:)
    { change_made: true, token: set_last_used_or_created_as_default(user_id:) }
  end

  # -----------------------------------------------------------------------------

  # set a payment method as the default - while first setting all as not defaulted
  def set_as_default
    HawthorneCore::UserPaymentMethod.where(user_id:).update_all(default: false)
    update_columns(default: true)
  end

  # -----------------------------------------------------------------------------

  # as stripe is our merchant, add the stripe payment method
  def self.perform_add(...) = add_stripe_credit_card(...)

  # -----------------------------------------------------------------------------

  # (soft) delete the payment method
  # as stripe is our merchant, detach the payment method within stripe - if the delete request is from the user
  # lastly, go through the payment methods and clean up a users defaulted payment methods
  def perform_delete(detach_requested_by_user: false)
    soft_delete
    HawthorneCore::Services::StripeSvc.detach_payment_method(user_id:, payment_method_id:) if detach_requested_by_user
    HawthorneCore::UserAction::Log.remove_payment_method(note: { token:, detach_requested_by_user: })
    HawthorneCore::UserPaymentMethod.clean_defaulted(user_id:)
  end

  # -----------------------------------------------------------------------------

end