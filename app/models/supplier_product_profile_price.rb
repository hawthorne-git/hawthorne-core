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

  # the member price may not be above the price; and while adhering to MAP, may only go below
  # MAP when the supplier allows it. only checked when it's set or changed, so automatic
  # repricing never fails on it (a shopper gets the lowest price anyway, and if things change
  # later the member price is held at MAP, see SupplierProductProfile#member_price_or_default)
  validate :member_price_not_above_price, if: :member_price_changed?
  validate :member_price_not_below_map, if: :member_price_changed?

  # a preorder discount is a rate: above 0, below 1 (100%)
  validates :preorder_discount, numericality: { greater_than: 0, less_than: 1 }, allow_nil: true

  # while adhering to MAP, the preorder price may only go below it when the supplier allows
  # it; only checked when the discount is set or changed, so automatic repricing never fails
  # on it (if things change later, the preorder price is held at MAP, see SupplierProductProfile#preorder_price)
  validate :preorder_price_not_below_map, if: :preorder_discount_changed?

  # -----------------------------------------------------------------------------

  private

  def hawthorne_only_prices
    return if marketplace&.hawthorne?

    errors.add(:member_price, 'can only be set on Hawthorne') if member_price
    errors.add(:preorder_discount, 'can only be set on Hawthorne') if preorder_discount
  end

  def preorder_price_not_below_map
    profile = supplier_product_profile
    return if preorder_discount.nil? || price.nil? || profile.nil? || profile.preorder_below_map_allowed?

    preorder_price = profile.discounted_preorder_price(price, preorder_discount)
    return if preorder_price >= profile.map_price

    errors.add(:preorder_discount, "would put the preorder price (#{format_price(preorder_price)}) below the MAP price (#{format_price(profile.map_price)}); the supplier doesn't allow preorder pricing below MAP")
  end

  def member_price_not_below_map
    profile = supplier_product_profile
    return if member_price.nil? || profile.nil? || profile.member_below_map_allowed? || member_price >= profile.map_price

    errors.add(:member_price, "(#{format_price(member_price)}) can't be below the MAP price (#{format_price(profile.map_price)}); the supplier doesn't allow member pricing below MAP")
  end

  def format_price(value) = ActiveSupport::NumberHelper.number_to_currency(value)

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
