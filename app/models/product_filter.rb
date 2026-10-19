# the supplier / price range filters on a product listing page (see ProductFiltersComponent), applied to a scope of
# products. prices are per shopper (sale / member prices), so they are filtered in ruby rather than in sql
class ProductFilter

  # the price range options, by param value: [label, min (inclusive), max (exclusive)]
  PRICE_RANGES = {
    'under-75' => ['Under $75', nil, 75],
    '75-100' => ['$75 – $100', 75, 100],
    '100-150' => ['$100 – $150', 100, 150],
    '150-200' => ['$150 – $200', 150, 200],
    '200-up' => ['$200 & up', 200, nil]
  }.freeze

  # the sort options, by param value; the first is the default
  SORTS = {
    'name' => 'Name',
    'price-asc' => 'Price: Low to High',
    'price-desc' => 'Price: High to Low'
  }.freeze

  attr_reader :selected_supplier_tokens, :selected_price_ranges, :sort

  # scope: the listing's products; preload supplier_product_profile: [:supplier, :supplier_product_profile_prices]
  # params: the request's params (supplier[] = supplier tokens, price[] = PRICE_RANGES keys, sort = a SORTS key)
  # logged_in: whether the shopper is signed in, so members are filtered / sorted by their member price
  def initialize(scope, params:, logged_in:)
    @products = scope.to_a
    @selected_supplier_tokens = Array(params[:supplier]).map(&:to_s) & supplier_tokens
    @selected_price_ranges = Array(params[:price]).map(&:to_s) & PRICE_RANGES.keys
    @sort = SORTS.key?(params[:sort].to_s) ? params[:sort].to_s : SORTS.keys.first
    @logged_in = logged_in
  end

  # -----------------------------------------------------------------------------

  # the products matching every selected filter (all of them when none are selected), in the selected sort order
  def products
    @filtered ||= sorted(@products.select { |product| supplier_match?(product) && price_match?(product) })
  end

  def default_sort? = @sort == SORTS.keys.first

  # the params for this listing with the given changes (ex: a different sort), leaving out empty / default values
  def params_with(**changes)
    { supplier: @selected_supplier_tokens, price: @selected_price_ranges, sort: @sort }
      .merge(changes)
      .compact_blank
      .reject { |key, value| key == :sort && value == SORTS.keys.first }
  end

  def any_selected? = @selected_supplier_tokens.any? || @selected_price_ranges.any?

  # the supplier options, by name: [supplier, count], counting the products that match the price filter so each
  # count is what selecting that supplier would add
  def supplier_options
    @products.select { |product| price_match?(product) }
             .group_by { |product| supplier(product) }
             .map { |supplier, products| [supplier, products.size] }
             .sort_by { |supplier, _| supplier.handle.downcase }
  end

  # every supplier in the listing, by name (the filter drawer lists them all, whatever else is selected)
  def suppliers = @products.map { |product| supplier(product) }.uniq.sort_by { |supplier| supplier.handle.downcase }

  # each product's [supplier token, PRICE_RANGES key (nil without a price)], so the filter drawer can count the
  # matching products as boxes are checked, before the filters are applied
  def facets = @products.map { |product| [supplier(product).token, price_range_key(product)] }

  # the price range options: [key, label, count], counting the products that match the supplier filter
  def price_range_options
    matching = @products.select { |product| supplier_match?(product) }
    PRICE_RANGES.map do |key, (label, min, max)|
      [key, label, matching.count { |product| in_range?(price(product), min, max) }]
    end
  end

  # -----------------------------------------------------------------------------

  private

  # by name, or by the shopper's price (then name); products without a price go last
  def sorted(products)
    by_name = products.sort_by { |product| product.handle.downcase }
    return by_name if @sort == 'name'
    priced, unpriced = by_name.partition { |product| price(product) }
    direction = @sort == 'price-desc' ? -1 : 1
    priced.sort_by.with_index { |product, i| [price(product) * direction, i] } + unpriced
  end

  def supplier_tokens =@products.map { |product| supplier(product).token }.uniq

  def supplier_match?(product)
    @selected_supplier_tokens.empty? || @selected_supplier_tokens.include?(supplier(product).token)
  end

  def price_match?(product)
    return true if @selected_price_ranges.empty?
    @selected_price_ranges.any? { |key| in_range?(price(product), *PRICE_RANGES[key].drop(1)) }
  end

  def price_range_key(product)
    PRICE_RANGES.find { |_, (_, min, max)| in_range?(price(product), min, max) }&.first
  end

  def in_range?(price, min, max)
    price.present? && (min.nil? || price >= min) && (max.nil? || price < max)
  end

  # the price this shopper sees, looked up once per product
  def price(product)
    (@prices ||= {})[product.product_id] ||= product.price_for_shopper(logged_in: @logged_in, hawthorne:)
  end

  # the supplier via the (preloaded) profile; always the same as products.supplier_id
  def supplier(product) = product.supplier_product_profile.supplier

  def hawthorne = @hawthorne ||= Marketplace.hawthorne

end
