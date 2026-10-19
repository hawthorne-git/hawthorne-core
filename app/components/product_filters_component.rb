class ProductFiltersComponent < ViewComponent::Base

  # the filter bar above a product listing: filter (not wired up yet), supplier and price range dropdowns, then the
  # item count and sort by (not wired up yet) on the right. the dropdowns submit a get form back to the listing
  #
  # filter: a ProductFilter for the listing
  # url: the listing page's path, which the form submits to
  def initialize(filter:, url:)
    @filter = filter
    @url = url
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

end
