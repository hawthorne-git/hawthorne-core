# v3.0

class HawthorneCore::SiteTextMessage < HawthorneCore::ActiveRecordBase

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'site_text_messages'

  # -----------------------------------------------------------------------------

  def id = site_text_message_id

  # -----------------------------------------------------------------------------

  # creates a record
  def self.create_record(**attrs)
    with_writing { create!(attrs) }
  end

  # -----------------------------------------------------------------------------

end