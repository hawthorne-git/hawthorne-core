class ProductFiltersComponent < ViewComponent::Base

  # the filter bar above a product listing: filter (not wired up yet), type (when the filter has one), quilt size (while
  # quilt is the selected type), difficulty (when the filter has one), supplier, price range and stock dropdowns, then
  # the item count and sort by (not wired up yet) on the right. the dropdowns submit a get form back to the listing.
  # with search, a search box goes above the bar; it submits q, which the listing turns into params (see ProductSearch)
  #
  # filter: a ProductFilter for the listing
  # url: the listing page's path, which the form submits to
  # search: whether to show the search box
  # search_example: what the search box's placeholder suggests searching for (ex: 'a lap quilt kit in stock')
  # price_chip: whether the price range filter (with on sale) has a dropdown in the filter bar; without one it's only in
  #   the filter drawer, opened by the filter button
  # sale: whether the price range filter has on sale (for a listing whose products are never on sale)
  # price_ranges: whether the price range filter in the filter drawer has the preset price ranges; without them it's
  #   just the custom min / max boxes (for a listing whose prices are all low)
  # price_step: how much the custom price boxes' up / down arrows change the price, in dollars (nil for 1); any price
  #   can still be typed
  def initialize(filter:, url:, search: false, search_example: 'a lap quilt kit in stock', price_chip: true,
                 sale: true, price_ranges: true, price_step: nil)
    @filter = filter
    @url = url
    @search = search
    @search_example = search_example
    @price_chip = price_chip
    @sale = sale
    @price_ranges = price_ranges
    @price_step = price_step
  end

  # -----------------------------------------------------------------------------

  # a dropdown's button label, with how many of its options are selected (ex: "Supplier (2)")
  def label(text, selected)
    selected.empty? ? text : "#{text} (#{selected.size})"
  end

  # this listing's url with the given changes to its params (ex: a different sort), keeping the rest
  def listing_path(**changes)
    query = @filter.params_with(**changes).to_query
    query.empty? ? @url : "#{@url}?#{query}"
  end

  # the given params as hidden fields, so applying a filter keeps them (ex: the search's search, keywords and sku)
  def hidden_fields(*keys)
    fields = @filter.params_with.slice(*keys).flat_map do |key, value|
      name = value.is_a?(Array) ? "#{key}[]" : key
      Array(value).map { |item| hidden_field_tag(name, item, id: nil) }
    end
    safe_join(fields)
  end

  # what the search narrowed by beyond the filter chips: its keywords, with their related words to show on hover
  # (ex: ['“ocean”', 'Also matches: nautical, beach'])
  def search_details
    @filter.keyword_groups.map { |word, related| ["“#{word}”", ("Also matches: #{related.join(', ')}" if related.any?)] }
  end

  # the price range button's label: on sale when it's checked, then the custom price when there is one (ex: "Price
  # Range: On Sale, Up to $90"), else how many price ranges are checked (ex: "Price Range (2)", "Price Range: On Sale,
  # 2 ranges")
  def price_range_label
    parts = []
    parts << 'On Sale' if @filter.on_sale?
    if @filter.custom_price?
      min, max = [@filter.min_price, @filter.max_price].map { |price| price && number_to_currency(price, precision: (price % 1).zero? ? 0 : 2) }
      parts << range_text(min, max)
    elsif @filter.on_sale? && @filter.selected_price_ranges.any?
      parts << pluralize(@filter.selected_price_ranges.size, 'range')
    end
    parts.any? ? "Price Range: #{parts.join(', ')}" : label('Price Range', @filter.selected_price_ranges)
  end

  # the quilt size button's label: the custom size when there is one (ex: "Size: W 50″ – 70″, L 60″ & up"), else how
  # many quilt sizes are checked
  def quilt_size_label
    return label('Size', @filter.selected_quilt_sizes) unless @filter.custom_quilt_size?
    sides = [['W', @filter.min_width, @filter.max_width], ['L', @filter.min_length, @filter.max_length]]
    parts = sides.filter_map do |side, min, max|
      "#{side} #{range_text(inches_text(min), inches_text(max))}" if min || max
    end
    "Size: #{parts.join(', ')}"
  end

  # the custom min / max price boxes, in the filter bar and the filter drawer (see ProductFilterBoxesComponent)
  def price_boxes
    rows = [{ name: 'price', aria: 'price', min: @filter.min_price, max: @filter.max_price }]
    render(ProductFilterBoxesComponent.new(kind: :price, rows:, prefix: '$', step: @price_step || 'any', divider: @price_ranges))
  end

  # the custom quilt size's min / max boxes, a row for width and (when the filter has one) length
  def size_boxes
    rows = [{ name: 'width', label: 'Width', aria: 'width, in inches', min: @filter.min_width, max: @filter.max_width }]
    if @filter.quilt_lengths?
      rows << { name: 'length', label: 'Length', aria: 'length, in inches', min: @filter.min_length, max: @filter.max_length }
    end
    render(ProductFilterBoxesComponent.new(kind: :size, rows:, suffix: '″'))
  end

  # -----------------------------------------------------------------------------

  private

  # a number without a needless decimal (ex: 90 rather than 90.0)
  def number_box_value(number) = number && ((number % 1).zero? ? number.to_i : number)

  # a min / max as text (ex: "$50 – $90", "Up to $90", "$50 & up"); at least one is given
  def range_text(min, max)
    if min && max then "#{min} – #{max}"
    elsif max then "Up to #{max}"
    else "#{min} & up"
    end
  end

  # inches as text (ex: 60″, 81.5″; nil without any)
  def inches_text(inches) = inches && "#{number_box_value(inches)}″"

end
