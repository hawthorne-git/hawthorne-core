class SupplierProductProfile < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  # the refresh flags are only work flags for RefreshProfileCostsJob; clearing them isn't a change worth a version
  has_paper_trail versions: { class_name: 'Version' }, ignore: [:refresh_landed_cost, :refresh_loaded_cost]

  GRAMS_PER_POUND = BigDecimal('453.59237')

  # inbound freight is charged on the measured weight plus this much for packing material
  PACKING_WEIGHT_RATE = BigDecimal('0.10')

  # -----------------------------------------------------------------------------

  self.table_name = 'supplier_product_profiles'
  self.primary_key = 'supplier_product_profile_id'

  def id = supplier_product_profile_id

  # -----------------------------------------------------------------------------

  belongs_to :supplier
  belongs_to :product_type

  has_many :supplier_product_profile_prices, inverse_of: :supplier_product_profile
  has_many :products

  # once products use the profile, its supplier and product type can't change (products copy both from their profile)
  validate :supplier_and_product_type_locked_once_used

  # an active product needs an active profile, so a profile can't be inactivated while active products use it
  validate :no_active_products_when_inactivating

  # landed_cost and loaded_cost are captured on every save, which also clears both refresh flags
  before_save :capture_costs

  # then the price on every active marketplace is recalculated (see refresh_marketplace_price)
  after_save :refresh_marketplace_prices

  # -----------------------------------------------------------------------------

  # the margin on a marketplace: the profile's (hawthorne) margin scaled by the
  # marketplace's multiplier (ex: 0.200 x 0.750 = 0.150)
  def margin_rate_for(marketplace) = (margin_rate || 0) * marketplace.margin_multiplier

  # the cost to process one unit, set on the profile's product type (0 when there is no product type yet)
  def processing_cost = product_type&.processing_cost_per_unit || 0

  # what we pay: the supplier's list price less the supplier's discount, rounded
  # to the cent (ex: 62.96 at 10% off = 56.66); the list price when there is no discount / supplier
  def net_cost
    return nil if supplier_list_price.nil?

    (supplier_list_price * (1 - (supplier&.discount_rate || 0))).round(2)
  end

  # the weight inbound freight is charged on: the measured weight plus packing
  # material, rounded to the gram (ex: 1483 g + 10% = 1631 g)
  def packed_weight_in_grams
    return nil if weight_in_grams.nil?

    (weight_in_grams * (1 + PACKING_WEIGHT_RATE)).round
  end

  # the cost once the unit is in our warehouse: net cost, plus the supplier's credit
  # card fee and tariff (both on the net cost), plus inbound freight (the supplier's
  # cost per lb x the packed weight); rounded to the cent. nil when there is no
  # supplier list price / weight yet. this is calculated from current values; the
  # landed_cost column holds the value captured at the last save
  def calculated_landed_cost
    return nil if supplier_list_price.nil? || weight_in_grams.nil?

    cc_fee = net_cost * (supplier&.cc_fee_rate || 0)
    tariff = net_cost * (supplier&.tariff_rate || 0)
    freight = (supplier&.freight_cost_per_lb || 0) * packed_weight_in_grams / GRAMS_PER_POUND
    (net_cost + cc_fee + tariff + freight).round(2)
  end

  # the share of what we pay that we don't get back (by product type; ex: fabric
  # remnants sold at a deep discount); 0 when nothing is wasted (ex: sewing kits)
  def waste_rate = product_type&.waste_rate || 0

  # the waste allowance each sold unit carries: the landed cost spread over the share
  # that isn't wasted, less the landed cost, rounded to the cent (ex: 20.00 at 1.5%
  # waste = 20.00 / 0.985 - 20.00 = 0.30). nil when there is no landed cost yet
  def waste_cost
    landed = calculated_landed_cost
    landed.nil? ? nil : (landed / (1 - waste_rate) - landed).round(2)
  end

  # the cost once the unit is ready to sell: landed cost plus the waste allowance plus
  # processing (both by product type). calculated from current values; the
  # loaded_cost column holds the value captured at the last save
  def calculated_loaded_cost
    landed = calculated_landed_cost
    landed.nil? ? nil : landed + waste_cost + processing_cost
  end

  # the calculated price on a marketplace: the selling price that, after the
  # marketplace's transaction fee, leaves the margin over loaded cost and shipping
  # loss; rounded up to the cent. this is the actual calculation, MAP is NOT applied
  # (see automatic_price_for). nil when there is no supplier list price / weight
  # yet, or the fee and margin take 100% or more of the price
  def calculated_price_for(marketplace)
    loaded = calculated_loaded_cost
    return nil if loaded.nil?

    remainder = 1 - marketplace.transaction_rate - margin_rate_for(marketplace)
    return nil unless remainder.positive?

    shipping_loss = marketplace.shipping_loss_per_100_grams * weight_in_grams / 100
    ((loaded + shipping_loss) / remainder).ceil(2)
  end

  # the profit from selling at a price on a marketplace: the price less the marketplace's
  # transaction fee (on the price), the loaded cost, and the shipping loss; rounded to the
  # cent. nil when there is no price / loaded cost
  def profit_at(price, marketplace)
    loaded = calculated_loaded_cost
    return nil if price.nil? || loaded.nil?

    shipping_loss = marketplace.shipping_loss_per_100_grams * weight_in_grams / 100
    (price - (price * marketplace.transaction_rate) - loaded - shipping_loss).round(2)
  end

  # the margin from selling at a price on a marketplace: its profit as a share of the
  # price (0.150 = 15%). nil when there is no price / profit
  def margin_at(price, marketplace)
    profit = profit_at(price, marketplace)
    return nil if profit.nil? || !price.positive?

    profit / price
  end

  # the profit at the calculated price (about the margin x the price; a little more,
  # since the calculated price is rounded up to the cent)
  def calculated_profit_for(marketplace) = profit_at(calculated_price_for(marketplace), marketplace)

  # the price on a marketplace when it isn't overridden: the calculated price, raised
  # to the MAP price when adhering to it and the calculated price is below it. nil
  # when there is no calculated price
  def automatic_price_for(marketplace)
    calculated = calculated_price_for(marketplace)
    return calculated if calculated.nil? || !adhere_to_map_price? || map_price.nil?

    [calculated, map_price].max
  end

  # the price row on a marketplace (nil when there isn't one yet)
  def price_row_for(marketplace) = supplier_product_profile_prices.find { |price| price.marketplace_id == marketplace.marketplace_id }

  # the saved price on a marketplace (nil when none is saved)
  def price_for(marketplace) = price_row_for(marketplace)&.price

  # the regular (advertised) price on hawthorne: the saved hawthorne price (kept current
  # by the repricing callbacks / jobs), else what it would be. pass the hawthorne
  # marketplace when pricing many profiles, to avoid looking it up each time
  def hawthorne_price(hawthorne = Marketplace.hawthorne)
    return nil if hawthorne.nil?

    price_for(hawthorne) || automatic_price_for(hawthorne)
  end

  # whether a member (logged in) price may go below the MAP price: always when not
  # adhering to MAP (or there is none); while adhering, only when the supplier allows it
  def member_below_map_allowed? = !adhere_to_map_price? || map_price.nil? || supplier&.allow_member_pricing_below_map? || false

  # the logged in price on hawthorne: the hawthorne price row's member price when set
  # (held at the MAP price when it may not go below it, ex: the supplier doesn't allow
  # member pricing below MAP); blank means no member discount, so the hawthorne price
  def member_price_or_default(hawthorne = Marketplace.hawthorne)
    return nil if hawthorne.nil?

    member = price_row_for(hawthorne)&.member_price
    return hawthorne_price(hawthorne) if member.nil?
    return member if member_below_map_allowed?

    [member, map_price].max
  end

  # the preorder discount on hawthorne, as a rate (0.10 = 10% off); nil when there isn't one
  def preorder_discount(hawthorne = Marketplace.hawthorne) = hawthorne && price_row_for(hawthorne)&.preorder_discount

  # whether a preorder price may go below the MAP price: always when not adhering to
  # MAP (or there is none); while adhering, only when the supplier allows it
  def preorder_below_map_allowed? = !adhere_to_map_price? || map_price.nil? || supplier&.allow_preorder_pricing_below_map? || false

  # a price less a preorder discount (a rate), rounded to the cent
  def discounted_preorder_price(price, discount) = (price * (1 - discount)).round(2)

  # the hawthorne price for a preorder: the regular price less the preorder discount,
  # rounded to the cent, but held at the MAP price when it may not go below it (ex: the
  # supplier stopped allowing it after the discount was set); nil without a preorder discount
  def preorder_price(hawthorne = Marketplace.hawthorne)
    discount = preorder_discount(hawthorne)
    regular = hawthorne_price(hawthorne)
    return nil if discount.nil? || regular.nil?

    discounted = discounted_preorder_price(regular, discount)
    preorder_below_map_allowed? ? discounted : [discounted, map_price].max
  end

  # recalculate the price row on a marketplace, creating it when missing; saving the row
  # updates its calculated price, and its price (with MAP applied) unless overridden (see
  # SupplierProductProfilePrice). skipped while there is no calculated price, since
  # both prices are required
  def refresh_marketplace_price(marketplace)
    return if calculated_price_for(marketplace).nil?

    # build through the association so the new row is in supplier_product_profile_prices right away
    row = price_row_for(marketplace) || supplier_product_profile_prices.build(marketplace:)
    row.save!
  end

  # -----------------------------------------------------------------------------

  private

  def no_active_products_when_inactivating
    return unless persisted? && deleted? && deleted_changed?

    count = products.where(deleted: false).count
    errors.add(:base, "Cannot be set as inactive while #{count} active #{'product'.pluralize(count)} #{count == 1 ? 'uses' : 'use'} it") if count.positive?
  end

  def supplier_and_product_type_locked_once_used
    return unless persisted? && (supplier_id_changed? || product_type_id_changed?)
    return unless products.exists?

    errors.add(:supplier_id, "can't be changed: products use this profile") if supplier_id_changed?
    errors.add(:product_type_id, "can't be changed: products use this profile") if product_type_id_changed?
  end

  def capture_costs
    self.landed_cost = calculated_landed_cost
    self.loaded_cost = calculated_loaded_cost
    self.refresh_landed_cost = false
    self.refresh_loaded_cost = false
  end

  def refresh_marketplace_prices
    Marketplace.active.each { |marketplace| refresh_marketplace_price(marketplace) }
  end

end
