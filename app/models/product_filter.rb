# the type / quilt size / difficulty / supplier / price range / stock filters on a product listing page (see
# ProductFiltersComponent), applied to a scope of products. a search (see ProductSearch) narrows the products first, by
# keywords matched against their names / descriptions / search text. the price filter is either price ranges or a
# custom min / max price, not both; likewise the quilt size filter is either quilt sizes or a custom min / max width
# and length. prices are per shopper (sale / member prices), so they are filtered in ruby rather than in sql. the on
# sale filter (in the price range dropdown) goes with either
class ProductFilter

  # the price range options, by param value: [label, min (inclusive), max (exclusive)]
  PRICE_RANGES = {
    'under-75' => ['Under $75', nil, 75],
    '75-100' => ['$75 – $100', 75, 100],
    '100-150' => ['$100 – $150', 100, 150],
    '150-200' => ['$150 – $200', 150, 200],
    '200-up' => ['$200 & up', 200, nil]
  }.freeze

  # the quilt size options, by param value: [label, min width (inclusive), max width (exclusive)], in inches. grouped
  # by width (the shorter side), since that decides whether a quilt covers a bed
  QUILT_SIZES = {
    'baby-wall' => ['Baby & Wall', nil, 50],
    'lap-throw' => ['Lap & Throw', 50, 68],
    'twin-full' => ['Twin & Full', 68, 88],
    'queen-king' => ['Queen & King', 88, nil]
  }.freeze

  # the stock options, by param value: label (see Product#in_stock?)
  STOCK_STATUSES = {
    'in-stock' => 'In Stock',
    'out-of-stock' => 'Out of Stock'
  }.freeze

  # the type whose products can be filtered by QUILT_SIZES
  QUILT_TYPE = 'quilt'

  # the sort options, by param value; the first is the default
  SORTS = {
    'name' => 'Name',
    'price-asc' => 'Price: Low to High',
    'price-desc' => 'Price: High to Low'
  }.freeze

  # the most keywords a search matches on
  MAX_KEYWORDS = 5

  attr_reader :search, :keywords, :min_price, :max_price, :min_width, :max_width, :min_length, :max_length,
              :selected_types, :selected_quilt_sizes, :selected_difficulties, :selected_supplier_tokens,
              :selected_price_ranges, :selected_stock, :sort

  # scope: the listing's products; preload supplier_product_profile: [:supplier, :supplier_product_profile_prices]
  # params: the request's params (search = what the shopper typed, shown in the search box; keywords[] = words every
  #   product's name, description or search text must contain; type[] = a type attr value, only one at a time;
  #   size[] = QUILT_SIZES keys, or min_width / max_width / min_length / max_length = a custom quilt size in inches,
  #   inclusive (which wins over size[]); difficulty[] = difficulty attr values; supplier[] = supplier tokens;
  #   price[] = PRICE_RANGES keys, or min_price / max_price = a custom price range, inclusive (which wins over price[]);
  #   sale = '1' for only products on sale (see Product#on_sale?); stock[] = a STOCK_STATUSES key, only one at a time;
  #   sort = a SORTS key)
  # logged_in: whether the shopper is signed in, so members are filtered / sorted by their member price
  # type_attr: the key of the product attr the type filter looks at (ex: 'project'); nil for no type filter
  # quilt_size_attr: the key of the product attr holding a quilt's width in inches (ex: 'width'), which the quilt size
  #   filter groups by while the QUILT_TYPE type is selected; nil for no quilt size filter
  # quilt_length_attr: the key of the product attr holding a quilt's length in inches (ex: 'length'), for the custom
  #   quilt size's min / max length; nil for a custom quilt size by width only
  # difficulty_attr: the key of the product attr the difficulty filter looks at (ex: 'difficulty'); nil for no
  #   difficulty filter
  def initialize(scope, params:, logged_in:, type_attr: nil, quilt_size_attr: nil, quilt_length_attr: nil,
                 difficulty_attr: nil)
    @logged_in = logged_in
    @search = params[:search].to_s.squish.presence
    @keywords = Array(params[:keywords]).map { |keyword| keyword.to_s.squish.downcase }.compact_blank.uniq.first(MAX_KEYWORDS)
    @min_price, @max_price = number_range_params(params[:min_price], params[:max_price])
    @products = scope.to_a.select { |product| keyword_match?(product) }
    @type_attr = type_attr&.to_s
    @quilt_size_attr = quilt_size_attr&.to_s
    @quilt_length_attr = quilt_length_attr&.to_s
    @difficulty_attr = difficulty_attr&.to_s
    @selected_types = (Array(params[:type]).map(&:to_s) & types).first(1)
    if quilt_size_filter?
      @min_width, @max_width = number_range_params(params[:min_width], params[:max_width])
      @min_length, @max_length = number_range_params(params[:min_length], params[:max_length]) if quilt_lengths?
    end
    @selected_quilt_sizes = quilt_size_filter? && !custom_quilt_size? ? Array(params[:size]).map(&:to_s) & QUILT_SIZES.keys : []
    @selected_difficulties = Array(params[:difficulty]).map(&:to_s) & difficulties
    @selected_supplier_tokens = Array(params[:supplier]).map(&:to_s) & supplier_tokens
    @selected_price_ranges = custom_price? ? [] : Array(params[:price]).map(&:to_s) & PRICE_RANGES.keys
    @on_sale = params[:sale].to_s == '1'
    @selected_stock = (Array(params[:stock]).map(&:to_s) & STOCK_STATUSES.keys).first(1)
    @sort = SORTS.key?(params[:sort].to_s) ? params[:sort].to_s : SORTS.keys.first
  end

  # -----------------------------------------------------------------------------

  # the products matching every selected filter (all of them when none are selected), in the selected sort order
  def products
    @filtered ||= sorted(@products.select { |product| matches?(product) })
  end

  def default_sort? = @sort == SORTS.keys.first

  # the params for this listing with the given changes (ex: a different sort), leaving out empty / default values
  def params_with(**changes)
    { search: @search, keywords: @keywords, min_price: number_value(@min_price), max_price: number_value(@max_price),
      type: @selected_types, size: @selected_quilt_sizes, min_width: number_value(@min_width),
      max_width: number_value(@max_width), min_length: number_value(@min_length), max_length: number_value(@max_length),
      difficulty: @selected_difficulties,
      supplier: @selected_supplier_tokens, price: @selected_price_ranges, sale: ('1' if @on_sale), stock: @selected_stock,
      sort: @sort }
      .merge(changes)
      .compact_blank
      .reject { |key, value| key == :sort && value == SORTS.keys.first }
  end

  def any_selected?
    [@selected_types, @selected_quilt_sizes, @selected_difficulties, @selected_supplier_tokens, @selected_price_ranges,
     @selected_stock].any?(&:any?) || custom_price? || custom_quilt_size? || @on_sale
  end

  # whether only products on sale are shown
  def on_sale? = @on_sale

  # whether the listing is narrowed by a search
  def searched? = @search.present? || @keywords.any?

  # whether the price filter is a custom min / max price (rather than price ranges)
  def custom_price? = @min_price.present? || @max_price.present?

  # whether the quilt size filter is a custom min / max width and length (rather than quilt sizes)
  def custom_quilt_size? = [@min_width, @max_width, @min_length, @max_length].any?(&:present?)

  # whether the listing has a type filter, and any of its products have a type to filter by
  def type_filter? = types.any?

  # the type options, in the type attr's option order: [type, label, count], counting the products that match the
  # other filters (the quilt size filter only for the quilt type) so each count is what selecting that type would add
  def type_options
    matching = @products.select { |product| matches?(product, except: [:type, :size]) }
    types.map do |value|
      count = matching.count { |product| type(product) == value && (value != QUILT_TYPE || quilt_size_match?(product)) }
      [value, type_label(value), count]
    end
  end

  # a type's name (ex: 'table_runner' => 'Table Runner'): its option's handle, or the value humanized when it's no
  # longer an option
  def type_label(value) = option_handles(@type_attr)[value] || value.humanize

  # every type in the listing (the filter drawer lists them all, whatever else is selected), in the type attr's option
  # order
  def types = @types ||= select_values(@type_attr)

  # whether the listing offers the quilt size filter (its section shows in the filter drawer while quilt is checked)
  def quilt_sizes? = @quilt_size_attr.present? && types.include?(QUILT_TYPE)

  # whether the quilt size filter applies: only while the quilt type is selected
  def quilt_size_filter? = quilt_sizes? && @selected_types == [QUILT_TYPE]

  # whether the custom quilt size has a min / max length (as well as width)
  def quilt_lengths? = quilt_sizes? && @quilt_length_attr.present?

  # the quilt size options: [key, label, count], counting the products that match the other filters
  def quilt_size_options
    matching = @products.select { |product| matches?(product, except: :size) }
    QUILT_SIZES.map do |key, (label, min, max)|
      [key, label, matching.count { |product| in_range?(quilt_width(product), min, max) }]
    end
  end

  # whether the listing has a difficulty filter, and any of its products have a difficulty to filter by
  def difficulty_filter? = difficulties.any?

  # the difficulty options, in the difficulty attr's option order: [difficulty, label, count], counting the products
  # that match the other filters so each count is what selecting that difficulty would add
  def difficulty_options
    matching = @products.select { |product| matches?(product, except: :difficulty) }
    difficulties.map { |value| [value, difficulty_label(value), matching.count { |product| difficulty(product) == value }] }
  end

  # a difficulty's name (ex: 'confident_beginner' => 'Confident Beginner'): its option's handle, or the value
  # humanized when it's no longer an option
  def difficulty_label(value) = option_handles(@difficulty_attr)[value] || value.humanize

  # every difficulty in the listing (the filter drawer lists them all, whatever else is selected), in the difficulty
  # attr's option order
  def difficulties = @difficulties ||= select_values(@difficulty_attr)

  # the supplier options, by name: [supplier, count], counting the products that match the other filters so each
  # count is what selecting that supplier would add. every supplier in the listing is an option, even with no matching
  # products, so a selected supplier stays checked (and isn't dropped when the filters are applied again)
  def supplier_options
    matching = @products.select { |product| matches?(product, except: :supplier) }
    suppliers.map { |supplier| [supplier, matching.count { |product| supplier(product) == supplier }] }
  end

  # every supplier in the listing, by name (the filter drawer lists them all, whatever else is selected)
  def suppliers = @products.map { |product| supplier(product) }.uniq.sort_by { |supplier| supplier.handle.downcase }

  # each product's [supplier token, PRICE_RANGES key (nil without a price), type (nil without one), QUILT_SIZES key
  # (nil without a width), difficulty (nil without one), price (nil without one), STOCK_STATUSES key, quilt width and
  # length (nil for any other product, or without one), whether it's on sale], so the filter drawer can count the
  # matching products as boxes are checked, before the filters are applied
  def facets
    @products.map do |product|
      quilt = type(product) == QUILT_TYPE
      [supplier(product).token, price_range_key(product), type(product), quilt_size_key(product), difficulty(product),
       price(product)&.to_f, stock_key(product), (quilt_width(product)&.to_f if quilt),
       (quilt_length(product)&.to_f if quilt), product.on_sale?(hawthorne)]
    end
  end

  # how many products on sale match the other filters, for the on sale option's count
  def sale_count
    @products.count { |product| matches?(product, except: :sale) && product.on_sale?(hawthorne) }
  end

  # the price range options: [key, label, count], counting the products that match the other filters
  def price_range_options
    matching = @products.select { |product| matches?(product, except: :price) }
    PRICE_RANGES.map do |key, (label, min, max)|
      [key, label, matching.count { |product| in_range?(price(product), min, max) }]
    end
  end

  # the stock options: [key, label, count], counting the products that match the other filters
  def stock_options
    matching = @products.select { |product| matches?(product, except: :stock) }
    STOCK_STATUSES.map { |key, label| [key, label, matching.count { |product| stock_key(product) == key }] }
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

  # a min / max param pair (ex: min_price / max_price) as numbers, swapped when the min is over the max
  def number_range_params(min, max)
    min, max = number_param(min), number_param(max)
    min && max && min > max ? [max, min] : [min, max]
  end

  # a price / size param as a number (nil when it's blank, not a number, or not positive)
  def number_param(value)
    number = Float(value.to_s, exception: false)
    number if number&.positive?
  end

  # a price / size limit for the listing's params (ex: 100 rather than 100.0)
  def number_value(number) = number && (number % 1).zero? ? number.to_i : number

  # whether every keyword is in the product's name, description or search text (see Ai::ProductSearchTextJob)
  def keyword_match?(product)
    return true if @keywords.empty?
    text = "#{product.handle} #{product.description} #{product.search_text}".downcase
    @keywords.all? { |keyword| text.include?(keyword) }
  end

  # whether the shopper's price is within the custom min / max price (inclusive)
  def price_limit_match?(product)
    price = price(product)
    price.present? && (@min_price.nil? || price >= @min_price) && (@max_price.nil? || price <= @max_price)
  end

  # whether the quilt's width and length are within the custom min / max width and length (inclusive)
  def quilt_size_limit_match?(product)
    within?(quilt_width(product), @min_width, @max_width) && within?(quilt_length(product), @min_length, @max_length)
  end

  # whether a value is within an inclusive min / max; nil limits are open, and with no limits any value (or none) is
  def within?(value, min, max)
    return true if min.nil? && max.nil?
    value.present? && (min.nil? || value >= min) && (max.nil? || value <= max)
  end

  # whether the product matches every selected filter, leaving out the given ones (:type, :size, :difficulty,
  # :supplier, :price, :sale, :stock), so an option's count can be what selecting it would add
  def matches?(product, except: [])
    except = Array(except)
    (except.include?(:type) || type_match?(product)) &&
      (except.include?(:size) || quilt_size_match?(product)) &&
      (except.include?(:difficulty) || difficulty_match?(product)) &&
      (except.include?(:supplier) || supplier_match?(product)) &&
      (except.include?(:price) || price_match?(product)) &&
      (except.include?(:sale) || sale_match?(product)) &&
      (except.include?(:stock) || stock_match?(product))
  end

  def type_match?(product)
    @selected_types.empty? || @selected_types.include?(type(product))
  end

  def quilt_size_match?(product)
    return quilt_size_limit_match?(product) if custom_quilt_size?
    return true if @selected_quilt_sizes.empty?
    @selected_quilt_sizes.any? { |key| in_range?(quilt_width(product), *QUILT_SIZES[key].drop(1)) }
  end

  def difficulty_match?(product)
    @selected_difficulties.empty? || @selected_difficulties.include?(difficulty(product))
  end

  def supplier_match?(product)
    @selected_supplier_tokens.empty? || @selected_supplier_tokens.include?(supplier(product).token)
  end

  def price_match?(product)
    return price_limit_match?(product) if custom_price?
    return true if @selected_price_ranges.empty?
    @selected_price_ranges.any? { |key| in_range?(price(product), *PRICE_RANGES[key].drop(1)) }
  end

  def sale_match?(product)
    !@on_sale || product.on_sale?(hawthorne)
  end

  def stock_match?(product)
    @selected_stock.empty? || @selected_stock.include?(stock_key(product))
  end

  def stock_key(product) = product.in_stock? ? 'in-stock' : 'out-of-stock'

  def price_range_key(product)
    PRICE_RANGES.find { |_, (_, min, max)| in_range?(price(product), min, max) }&.first
  end

  # the QUILT_SIZES key for a quilt's width (nil for any other product, or a quilt without a width)
  def quilt_size_key(product)
    return unless type(product) == QUILT_TYPE
    QUILT_SIZES.find { |_, (_, min, max)| in_range?(quilt_width(product), min, max) }&.first
  end

  def in_range?(value, min, max)
    value.present? && (min.nil? || value >= min) && (max.nil? || value < max)
  end

  # the price this shopper sees, looked up once per product
  def price(product)
    (@prices ||= {})[product.product_id] ||= product.price_for_shopper(logged_in: @logged_in, hawthorne:)
  end

  def type(product) = select_value(product, @type_attr)

  def difficulty(product) = select_value(product, @difficulty_attr)

  # the product's value for a Select attr (nil without the attr, or when it isn't set)
  def select_value(product, key)
    return if key.nil?
    value = product.attr_value(key)
    value if value.is_a?(String) && value.present?
  end

  # every value of a Select attr in the listing, in the attr's option order; a value that's no longer an option goes
  # last, by name
  def select_values(key)
    order = option_handles(key).keys
    @products.filter_map { |product| select_value(product, key) }
             .uniq
             .sort_by { |value| [order.index(value) || order.size, value.downcase] }
  end

  # the active options of a Select attr for the listing's product types, in order: value => handle
  def option_handles(key)
    return {} if key.nil?
    @option_handles ||= ProductTypeAttr.includes(:product_attr, :product_type_attr_options)
                                       .where(product_type_id: @products.map(&:product_type_id).uniq)
                                       .group_by(&:key)
                                       .transform_values { |type_attrs| active_option_handles(type_attrs) }
    @option_handles.fetch(key, {})
  end

  def active_option_handles(type_attrs)
    type_attrs.flat_map { |type_attr| type_attr.product_type_attr_options.select(&:active?) }
              .to_h { |option| [option.value, option.handle] }
  end

  # the product's width for the quilt size filter, in inches (nil without a quilt size filter, or when it isn't set)
  def quilt_width(product)
    return if @quilt_size_attr.nil?
    value = product.attr_value(@quilt_size_attr)
    value if value.is_a?(Numeric)
  end

  # the product's length for the custom quilt size, in inches (nil without a length attr, or when it isn't set)
  def quilt_length(product)
    return if @quilt_length_attr.nil?
    value = product.attr_value(@quilt_length_attr)
    value if value.is_a?(Numeric)
  end

  # the supplier via the (preloaded) profile; always the same as products.supplier_id
  def supplier(product) = product.supplier_product_profile.supplier

  def hawthorne = @hawthorne ||= Marketplace.hawthorne

end
