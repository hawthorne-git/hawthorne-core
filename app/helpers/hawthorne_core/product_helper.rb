module HawthorneCore::ProductHelper

  # ----------------------------------------------------------------------------- Currency
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  # return the number as a currency value
  # ex: if the nbr is 12.34, return: $12.34
  def currency(nbr)
    '$' + sprintf('%.2f', nbr)
  end

  # return the number, represented as an int, as a currency value
  # ex: if the nbr is 1234, return: $12.34
  def currency_from_int(nbr)
    currency(nbr.to_f / 100)
  end

  # ----------------------------------------------------------------------------- Inventory
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  def inventory_to_s(parent_product)
    return inventory_fabric_to_s(parent_product) if parent_product.fabric?
    'INVENTORY'
  end

  # ---------------------------

  # return the fabric inventory in a displayable format
  # ex: if inventory is 11.625, return 11-1/2
  def inventory_fabric_to_s(parent_product)

    # if inventory is 15+ yards ... show to the full yard
    # ex: if inventory is 22.125, return 22
    return inventory_fabric_as_yardage(parent_product.inventory.floor) if parent_product.inventory >= 15

    # if inventory is 10+ yards ... show to the 1/2 yard
    # ex: if inventory is 11.625, return 11-1/2
    return inventory_fabric_as_yardage(((parent_product.inventory * 2.0).floor / 2.0)) if parent_product.inventory >= 10

    # if inventory is 5+ yards ... show to the 1/4 yard
    # ex: if inventory is 5.875, return 5-3/4
    return inventory_fabric_as_yardage(((parent_product.inventory * 4.0).floor / 4.0)).to_s if parent_product.inventory >= 5

    # else ... show to the 1/8 yard
    # ex: if inventory is 1.125, return 1-1/8
    inventory_fabric_as_yardage(((parent_product.inventory * 8.0).floor / 8.0))

  end

  # ---------------------------

  # return the fabric inventory in a displayable format
  # ex: if inventory is 11.5, return 11-1/2
  def inventory_fabric_as_yardage(nbr)

    # calculate the number of whole yards, then fractional yards
    whole_yards = nbr.floor.to_i
    fractional_yard = nbr.to_f - whole_yards.to_f

    # return the yardage as a whole number if there are no fractional yards
    return whole_yards.to_s if fractional_yard.zero?

    # in case where the fractional yard is not divisible by 1/8, round down
    fractional_yard = (fractional_yard * 8.0).floor / 8.0

    # get the fractional yard in a displayable format
    fractional_yard_to_s = ''
    fractional_yard_to_s = '1/8' if fractional_yard == 0.125
    fractional_yard_to_s = '1/4' if fractional_yard == 0.250
    fractional_yard_to_s = '3/8' if fractional_yard == 0.375
    fractional_yard_to_s = '1/2' if fractional_yard == 0.500
    fractional_yard_to_s = '5/8' if fractional_yard == 0.625
    fractional_yard_to_s = '3/4' if fractional_yard == 0.750
    fractional_yard_to_s = '7/8' if fractional_yard == 0.875

    # return just the fractional yard in a displayable format if there are no whole yards
    return fractional_yard_to_s if whole_yards.zero?

    # return the fabric inventory in a displayable format
    whole_yards.to_s + '-' + fractional_yard_to_s

  end

  # ---------------------------

  # return a list of add to cart options for a fabric product
  # from 1/2 yard to 5 yards ... sell by the 1/8 yard
  # from 5 yards to 10 yards ... sell by the 1/4 yard
  # from 10 yards to 15 yards ... sell by the 1/2 yard
  # then sell by the yards if 15+ ... up to 50 yards - this is the max allowed to purchase
  def inventory_fabric_add_to_cart_options(fabric_product)
    add_to_cart_options = []
    (0.5..fabric_product.inventory).step(0.125) do |quantity_to_list|
      next if (quantity_to_list > 5) && (quantity_to_list % 0.25 != 0)
      next if (quantity_to_list > 10) && (quantity_to_list % 0.50 != 0)
      next if (quantity_to_list > 15) && (quantity_to_list % 1.00 != 0)
      next if (quantity_to_list > 50)
      add_to_cart_options.push(quantity_to_list)
    end
    add_to_cart_options
  end

  # ----------------------------------------------------------------------------- Stock Status
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  # get the stock status of a parent product
  # return an out of stock message if there is no inventory for purchase
  def stock_status(parent_product)
    return 'Out of stock' unless parent_product.inventory?
    inventory_to_s(parent_product) + ' ' + unit(parent_product) + ' in stock'
  end

  # ----------------------------------------------------------------------------- Unit
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

  # get the unit of the product ... which is determined by its product type and inventory
  # ex: if it is a fabric product with an inventory of 1.125, the return unit is: yards
  def unit(parent_product)
    return unit_fabric(parent_product) if parent_product.fabric?
    'units'
  end

  # ---------------------------

  # get the unit of a fabric product
  def unit_fabric(parent_product)
    parent_product.fabric_panel? ? unit_fabric_panel(parent_product) : unit_fabric_yard(parent_product)
  end

  # get the unit of a fabric product sold by the panel ... plural if greater than 1 panel is in stock
  def unit_fabric_panel(parent_product)
    (parent_product.inventory <= 1.0) ? 'panel' : 'panels'
  end

  # get the unit of a fabric product that is sold by the yard ... plural if greater than 1 yard is in stock
  def unit_fabric_yard(parent_product)
    (parent_product.inventory <= 1.0) ? 'yard' : 'yards'
  end

  #TODO
  def unit_fabric_yard_inv(nbr)
    (nbr <= 1.0) ? 'yard' : 'yards'
  end

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------

end
