class HawthorneCore::SentTextMessage < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'sent_text_messages'
  self.primary_key = 'sent_text_message_id'

  def id = sent_text_message_id

  # -----------------------------------------------------------------------------

end