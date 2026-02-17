module HawthorneCore::CalcHelper

  # -----------------------------------------------------------------------------

  # calculate the grams per square meter (gsm) of a material,
  # given its grams per linear yard and its width
  def gsm(grams_per_linear_yard, yardage_width_in_inches)
    sq_yards_per_linear_yard = (36 * yardage_width_in_inches).to_f / (36 * 36).to_f
    grams_per_linear_yard / sq_yards_per_linear_yard * 1.196.to_f
  end

  # calculate the ounces per square yard of a material,
  # given its grams per linear yard and its width
  def oz_per_sq_yd(grams_per_linear_yard, yardage_width_in_inches)
    oz_per_linear_yard = grams_per_linear_yard / 28.35
    sq_yards_per_linear_yard = (36 * yardage_width_in_inches).to_f / (36 * 36).to_f
    sprintf('%.1f', (oz_per_linear_yard / sq_yards_per_linear_yard))
  end

  # -----------------------------------------------------------------------------

  # calculate the number to the 1/8 inches
  # as this is the same logic used to show fabric inventory, re-use this method
  def to_the_eighth_inches(nbr)
    inventory_fabric_as_yardage(nbr).to_s + '"'
  end

  # -----------------------------------------------------------------------------

end
