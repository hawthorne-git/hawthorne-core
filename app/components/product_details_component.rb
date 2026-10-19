class ProductDetailsComponent < ViewComponent::Base

  # responsive widths and sizes for the gallery's images: half the quick view / page, full width on phones
  IMAGE_WIDTHS = [480, 720, 960, 1280].freeze
  IMAGE_SIZES = '(max-width: 768px) 100vw, 600px'

  # a product's gallery and details, shown in the quick view (see ProductListComponent) and on the product page
  #
  # product: preload product_images: { image: :image_type } and
  # supplier_product_profile: [:supplier, :supplier_product_profile_prices] to avoid a query per image / price
  # logged_in: whether the shopper is signed in, so members see their member price
  # full_page: the product page (full description) rather than the quick view (truncated description, a link to the
  # product page, and a close button)
  # dialog_id: the quick view <dialog>'s id, which the close button closes
  def initialize(product:, logged_in:, full_page: false, dialog_id: nil)
    @product = product
    @logged_in = logged_in
    @full_page = full_page
    @dialog_id = dialog_id
  end

  # -----------------------------------------------------------------------------

  # the regular hawthorne price
  def regular_price = @product.hawthorne_price(hawthorne)

  # the lowest price this shopper sees (sale / member price when it applies)
  def shopper_price = @product.price_for_shopper(logged_in: @logged_in, hawthorne:)

  # the whole-number percent saved off the regular price (nil when there is no saving)
  def savings_percent(regular, shopper)
    return unless regular&.positive? && shopper && shopper < regular
    ((regular - shopper) / regular * 100).round
  end

  # the main image, then the additional images in order
  def images = [@product.main_image, *@product.additional_images].compact

  def image(image)
    render ImageComponent.new(image:, widths: IMAGE_WIDTHS, sizes: IMAGE_SIZES, alt: image.alt_text.presence || @product.handle)
  end

  def description
    @full_page ? @product.description : truncate(@product.description, length: 400, separator: ' ')
  end

  def product_path = helpers.product_path(slug: @product.url_slug)

  # -----------------------------------------------------------------------------

  private

  def hawthorne = Marketplace.hawthorne

end
