# v3.0

class HawthorneCore::Country < HawthorneCore::ActiveRecordBaseAdmin

  # -----------------------------------------------------------------------------

  self.table_name = 'countries'

  def id = country_id

  # -----------------------------------------------------------------------------

  def ship_to? = ship_to

  # -----------------------------------------------------------------------------

  # determine if a country exists with code alpha 2
  def self.code_alpha2_exists?(code_alpha2) = exists?(code_alpha2: code_alpha2, deleted: false)

  # determine if we ship to the country
  def self.ship_to?(code_alpha2) = exists?(code_alpha2: code_alpha2.strip.upcase, ship_to: true, deleted: false)

  # return all countries that we ship to
  def self.ship_to = select(:country_id, :handle, :code_alpha2).where(ship_to: true, deleted: false).order(handle: :asc)

  # -----------------------------------------------------------------------------

end