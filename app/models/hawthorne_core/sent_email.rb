# v3.0

class HawthorneCore::SentEmail < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'sent_emails'

  def id = sent_email_id

  # -----------------------------------------------------------------------------

  def self.create_record(**attrs) = create!(attrs)

  # -----------------------------------------------------------------------------

end