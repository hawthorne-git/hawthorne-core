# v3.0

class HawthorneCore::SiteEmail < HawthorneCore::ActiveRecordBase

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'site_emails'

  # -----------------------------------------------------------------------------

  def id = site_email_id

  # -----------------------------------------------------------------------------

  # creates a record
  def self.create_record(**attrs)
    with_writing { create!(attrs) }
  end

  # -----------------------------------------------------------------------------

end