class ProductFilterBoxesComponent < ViewComponent::Base

  # a filter's custom min / max boxes, under its options (see ProductFiltersComponent, which shows them in both the
  # filter bar and the filter drawer): "or", then a row of min / max boxes for each row
  #
  # kind: :price or :size; the boxes are marked data-filter-custom-<kind> for ProductFiltersComponent's script
  # rows: one hash per row: name (the boxes' params are min_<name> / max_<name>), label (shown before the row's boxes;
  #   nil for none), aria (what the boxes are, after "Minimum" / "Maximum", ex: 'width, in inches'), min / max (the
  #   current limits; nil for none)
  # prefix / suffix: shown in each box before / after its number (ex: '$', '″')
  # step: how much the boxes' up / down arrows change the number ('any' for 1); any number can still be typed
  def initialize(kind:, rows:, prefix: nil, suffix: nil, step: 'any')
    @kind = kind
    @rows = rows
    @prefix = prefix
    @suffix = suffix
    @step = step
  end

  # -----------------------------------------------------------------------------

  # a box's value (ex: 90 rather than 90.0; blank without one)
  def box_value(number) = number && ((number % 1).zero? ? number.to_i : number)

end
