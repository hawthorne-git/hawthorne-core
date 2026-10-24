# a shopper's search, one row each time one is made (ex: a sewing kit search, see ProductSearch), with how it was
# answered and the listing params it turned into. an AI answer's AiGeneration points at it (item_type Search)
class Search < ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # how a search was answered: asked the AI, an earlier AI answer from the cache, or the search's own words as keywords
  ANSWERED_BY_AI = 'AI'
  ANSWERED_BY_CACHE = 'CACHE'
  ANSWERED_BY_FALLBACK = 'FALLBACK'

  # -----------------------------------------------------------------------------

  self.table_name = 'searches'
  self.primary_key = 'search_id'

  def id = search_id

  # -----------------------------------------------------------------------------

end
