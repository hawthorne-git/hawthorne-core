# v3.0

class HawthorneCore::UserShippingAddress < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # -----------------------------------------------------------------------------

  self.table_name = 'user_shipping_addresses'

  def id = user_shipping_address_id

  def to_s = [street_address, street_address_extended, city, state_province, postal_code, country_code_alpha2].reject(&:blank?).join(', ')

  # -----------------------------------------------------------------------------

  # find the country handle
  # ex: code_alpha2 is 'US', return 'United States'
  def country_handle = HawthorneCore::Country.where(code_alpha2: country_code_alpha2).pick(:handle)

  # -----------------------------------------------------------------------------

end