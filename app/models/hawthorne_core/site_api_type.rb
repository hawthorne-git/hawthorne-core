# v3.0

class HawthorneCore::SiteApiType < ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'site_api_types'

  # -----------------------------------------------------------------------------

  IDS =
    {
      braintree: 2,
      brevo: 38,
      leonardo: 5,
      mailer_send: 1,
      media_modifier: 40,
      midjourney_api_frame: 4,
      midjourney_my_midjourney: 3
    }.freeze

  IDS.each do |key, value|
    define_singleton_method(key.to_s + '_id') { value }
  end

  # -----------------------------------------------------------------------------

end