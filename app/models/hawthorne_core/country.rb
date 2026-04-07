# v3.0

class HawthorneCore::Country < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'countries'

  def id = country_id

  # -----------------------------------------------------------------------------

  def ship_to? = ship_to

  def us? = (id == 235) || (handle == 'United States') || (code_alpha2 == 'US') || (code_alpha3 == 'USA')

  # -----------------------------------------------------------------------------

  # determine if a country exists with code alpha 2
  def self.code_alpha2_exists?(code_alpha2) = active.exists?(code_alpha2: code_alpha2)

  # determine if we ship to the country
  def self.ship_to?(code_alpha2) = active.exists?(code_alpha2: code_alpha2.strip.upcase, ship_to: true)

  # return all countries that we ship to
  def self.ship_to = select(:country_id, :handle, :code_alpha2).active.where(ship_to: true).order(handle: :asc)

  # -----------------------------------------------------------------------------

end