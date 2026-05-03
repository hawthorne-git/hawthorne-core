# v3.0

class HawthorneCore::Country < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'countries'

  def id = country_id

  # -----------------------------------------------------------------------------

  # determine if the country is shipped to
  def ship_to? = ship_to

  # determine if the country, is the United States
  def us? = (id == 235) || (handle == 'United States') || (code_alpha2 == 'US') || (code_alpha3 == 'USA')

  # -----------------------------------------------------------------------------

  # determine if an active country exists with this country code alpha 2
  def self.code_alpha2_exists?(code_alpha2:) = active.exists?(code_alpha2:)

  # determine if an active country exists, that we ship to, with this country code alpha 2
  def self.ship_to_code_alpha2?(code_alpha2:) = active.exists?(code_alpha2:, ship_to: true)

  # find all countries that we ship to, ordered
  def self.ship_to = active.where(ship_to: true).order(handle: :asc)

  # find a country, that we ship to, with county code alpha 2
  def self.ship_to_country_with_code_alpha2(code_alpha2:) = code_alpha2.present? ? active.find_by(code_alpha2:, ship_to: true) : nil

  # -----------------------------------------------------------------------------

end