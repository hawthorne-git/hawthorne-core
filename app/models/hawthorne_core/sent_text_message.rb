# v3.0

class HawthorneCore::SentTextMessage < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # -----------------------------------------------------------------------------

  self.table_name = 'sent_text_messages'

  def id = sent_text_message_id

  # -----------------------------------------------------------------------------

end