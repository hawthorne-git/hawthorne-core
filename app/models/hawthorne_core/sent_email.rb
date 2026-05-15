class HawthorneCore::SentEmail < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'sent_emails'
  self.primary_key = 'sent_email_id'

  def id = sent_email_id

  # -----------------------------------------------------------------------------

end