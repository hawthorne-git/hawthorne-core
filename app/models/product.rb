class Product < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'products'
  self.primary_key = 'product_id'

  def id = product_id

  # -----------------------------------------------------------------------------

  # pricing comes from the profile; optional until every product has one
  # (then products.supplier_product_profile_id is set NOT NULL)
  belongs_to :supplier_product_profile, optional: true
  belongs_to :product_type
  belongs_to :supplier
  belongs_to :artist, optional: true

  has_many :product_images, -> { order(:order_nbr) }
  has_many :images, through: :product_images

  attr_accessor :image_file

  # supplier_id / product_type_id always follow the profile (kept on products for
  # queries and the supplier + sku unique constraint)
  before_validation :copy_from_supplier_product_profile

  # the sale price is advertised on hawthorne, so it must beat the regular price and respect MAP
  validate :sale_price_allowed

  # an active product needs an active profile, so activating a product activates its profile too
  after_save :activate_supplier_product_profile, if: -> { saved_change_to_deleted?(from: true, to: false) }

  # -----------------------------------------------------------------------------

  # the first active image, by order; works off preloaded product_images when present
  def main_image = product_images.find { |product_image| product_image.active? && product_image.image.active? }&.image

  # -----------------------------------------------------------------------------

  # the list price on a marketplace: the profile's price there (nil without a profile / price)
  def list_price_for(marketplace) = marketplace && supplier_product_profile&.price_for(marketplace)

  # the regular (advertised) price on hawthorne; pass the hawthorne marketplace when
  # pricing many products, to avoid looking it up each time
  def hawthorne_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.hawthorne_price(hawthorne)

  # on sale (hawthorne only) when a sale price is set below the regular price
  def on_sale?(hawthorne = Marketplace.hawthorne)
    regular = hawthorne_price(hawthorne)
    sale_price.present? && regular.present? && sale_price < regular
  end

  # the logged in price on hawthorne, from the profile's hawthorne price (may be below MAP)
  def member_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.member_price_or_default(hawthorne)

  # the hawthorne price when presold, from the profile's hawthorne preorder discount (nil without one)
  def preorder_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.preorder_price(hawthorne)

  # the price a hawthorne shopper sees: the lowest of the regular price, the sale
  # price (when on sale), the member price (when logged in), and the preorder price
  # (when the product is being presold)
  def price_for_shopper(logged_in:, preorder: false, hawthorne: Marketplace.hawthorne)
    prices = [hawthorne_price(hawthorne)]
    prices << sale_price if on_sale?(hawthorne)
    prices << member_price(hawthorne) if logged_in
    prices << preorder_price(hawthorne) if preorder
    prices.compact.min
  end

  # -----------------------------------------------------------------------------

  private

  def copy_from_supplier_product_profile
    return if supplier_product_profile.nil?

    self.supplier_id = supplier_product_profile.supplier_id
    self.product_type_id = supplier_product_profile.product_type_id
  end

  def activate_supplier_product_profile
    supplier_product_profile.activate if supplier_product_profile&.deleted?
  end

  def sale_price_allowed
    return if sale_price.nil? || supplier_product_profile.nil?

    regular = hawthorne_price
    errors.add(:sale_price, "must be below the regular price (#{format_price(regular)})") if regular && sale_price >= regular

    profile = supplier_product_profile
    if profile.adhere_to_map_price? && profile.map_price && sale_price < profile.map_price
      errors.add(:sale_price, "can't be below the MAP price (#{format_price(profile.map_price)}) while adhering to it")
    end
  end

  def format_price(value) = ActiveSupport::NumberHelper.number_to_currency(value)

end
