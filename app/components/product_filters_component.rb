class ProductFiltersComponent < ViewComponent::Base

  # the filter bar above a product listing: filter (not wired up yet), type (when the filter has one), quilt size (while
  # quilt is the selected type), difficulty (when the filter has one), supplier, price range and stock dropdowns, then
  # the item count and sort by (not wired up yet) on the right. the dropdowns submit a get form back to the listing.
  # with search, a search box goes above the bar; it submits q, which the listing turns into params (see ProductSearch)
  #
  # filter: a ProductFilter for the listing
  # url: the listing page's path, which the form submits to
  # search: whether to show the search box
  # price_step: how much the custom price boxes' up / down arrows change the price, in dollars (nil for 1); any price
  #   can still be typed
  def initialize(filter:, url:, search: false, price_step: nil)
    @filter = filter
    @url = url
    @search = search
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

  # the search's params as hidden fields, so applying a filter keeps the search
  def search_fields
    fields = @filter.params_with.slice(:search, :keywords).flat_map do |key, value|
      name = value.is_a?(Array) ? "#{key}[]" : key
      Array(value).map { |item| hidden_field_tag(name, item, id: nil) }
    end
    safe_join(fields)
  end

  # what the search narrowed by beyond the filter chips: its keywords (ex: "batik")
  def search_details = @filter.keywords.map { |keyword| "“#{keyword}”" }

  # the price range button's label: the custom price when there is one (ex: "Price Range: Up to $90"), else how many
  # price ranges are checked
  def price_range_label
    return label('Price Range', @filter.selected_price_ranges) unless @filter.custom_price?
    min, max = [@filter.min_price, @filter.max_price].map { |price| price && number_to_currency(price, precision: (price % 1).zero? ? 0 : 2) }
    text = if min && max then "#{min} – #{max}"
           elsif max then "Up to #{max}"
           else "#{min} & up"
           end
    "Price Range: #{text}"
  end

  # a custom price box's value (ex: 90 rather than 90.0; blank without one)
  def price_box_value(price) = price && ((price % 1).zero? ? price.to_i : price)

end
