# v3.0

class HawthorneCore::UserShippingAddress < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::HasSiteSharingScope,
          HawthorneCore::HasToken

  # -----------------------------------------------------------------------------

  self.table_name = 'user_shipping_addresses'

  def id = user_shipping_address_id

  # -----------------------------------------------------------------------------

end