class SupplierProductProfilePrice < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'supplier_product_profile_prices'
  self.primary_key = 'supplier_product_profile_price_id'

  def id = supplier_product_profile_price_id

  # -----------------------------------------------------------------------------

  belongs_to :supplier_product_profile, inverse_of: :supplier_product_profile_prices
  belongs_to :marketplace

  # the calculated price follows the profile's costs and the marketplace's rates; done
  # before validation so the MAP check below sees the refreshed price
  before_validation :refresh_calculated_price

  # when the profile adheres to its MAP price, no price may be below it, overridden or not
  validate :price_not_below_map_price

  # the member (logged in) price and the preorder discount are hawthorne only
  validate :hawthorne_only_prices

  # the member price may not be above the price; only checked when it's set or changed, so
  # automatic repricing never fails on it (a shopper gets the lowest price anyway). it may be
  # below MAP: while adhering to MAP and the supplier doesn't allow member pricing below it,
  # members pay the MAP price instead (see SupplierProductProfile#member_price_or_default)
  validate :member_price_not_above_price, if: :member_price_changed?

  # a preorder discount is a rate: above 0, below 1 (100%). it may put the preorder price
  # below MAP: while adhering to MAP and the supplier doesn't allow preorder pricing below it,
  # the preorder price is held at MAP (see SupplierProductProfile#preorder_price)
  validates :preorder_discount, numericality: { greater_than: 0, less_than: 1 }, allow_nil: true

  # -----------------------------------------------------------------------------

  private

  def hawthorne_only_prices
    return if marketplace&.hawthorne?

    errors.add(:member_price, 'can only be set on Hawthorne') if member_price
    errors.add(:preorder_discount, 'can only be set on Hawthorne') if preorder_discount
  end

  def member_price_not_above_price
    return if member_price.nil? || price.nil?

    errors.add(:member_price, 'must be above zero') unless member_price.positive?
    errors.add(:member_price, "can't be above the price (#{ActiveSupport::NumberHelper.number_to_currency(price)})") if member_price > price
  end

  # an automatic price is already raised to the MAP price (see refresh_calculated_price),
  # so in practice this catches an overridden price
  def price_not_below_map_price
    profile = supplier_product_profile
    return unless profile&.adhere_to_map_price? && profile.map_price && price && price < profile.map_price

    errors.add(:price, "can't be below the MAP price (#{ActiveSupport::NumberHelper.number_to_currency(profile.map_price)}) while adhering to it")
  end

  # always capture the actual calculated price (MAP not applied); unless overridden,
  # the price follows it, raised to the MAP price when adhering (an overridden price
  # keeps whatever was entered)
  def refresh_calculated_price
    profile = supplier_product_profile
    calculated = profile.calculated_price_for(marketplace)
    return if calculated.nil?

    self.calculated_price = calculated
    self.price = profile.automatic_price_for(marketplace) unless override_calculated_price?
  end

end
