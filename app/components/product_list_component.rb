class ProductListComponent < ViewComponent::Base

  # responsive widths (css pixels) requested from cloudflare for a product card image
  IMAGE_WIDTHS = [320, 480, 640].freeze

  # the card image's sizes attribute: 2 columns on phones, otherwise 300px cards (see .product-list__grid)
  IMAGE_SIZES = '(max-width: 640px) 50vw, 300px'

  # products: preload product_images: { image: :image_type } and
  # supplier_product_profile: [:supplier, :supplier_product_profile_prices] to avoid a query per product
  # logged_in: whether the shopper is signed in, so members see their member price
  def initialize(products:, logged_in:)
    @products = products
    @logged_in = logged_in
  end

  # -----------------------------------------------------------------------------

  # the regular hawthorne price
  def regular_price(product) = product.hawthorne_price(hawthorne)

  # the lowest price this shopper sees (sale / member price when it applies)
  def shopper_price(product) = product.price_for_shopper(logged_in: @logged_in, hawthorne:)

  # a product's main image, sized for its card ("No image" when it has none)
  def image_for(product)
    image = product.main_image
    render ImageComponent.new(image:, widths: IMAGE_WIDTHS, sizes: IMAGE_SIZES, alt: image&.alt_text.presence || product.handle,
                              empty: tag.div('No image', class: 'product-card__no-image'))
  end

  def product_path(product) = helpers.product_path(slug: product.url_slug)

  # the quick view <dialog>'s id, which the card's plus button opens
  def quick_view_id(product) = "quick-view-#{product.token}"

  # -----------------------------------------------------------------------------

  private

  def hawthorne = Marketplace.hawthorne

end
