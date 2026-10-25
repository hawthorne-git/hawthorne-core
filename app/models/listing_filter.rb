# a listing page loaded with filters or a non-default sort (ex: sewing kits, see ProductFilter), one row per load, so
# which filters / sorts shoppers use (and which return nothing) can be seen. the plain listing isn't logged. bots
# aren't skipped here: their sessions are flagged later (see user_sessions.bot), so reports join on the session token
class ListingFilter < ActiveRecordBaseLog

  include HawthorneCore::HasSiteId

  # the same filters in the same session within this long aren't logged again (ex: a refresh, the back button)
  REPEAT_WITHIN = 30.minutes

  # how long rows are kept, before they're cleaned up
  KEEP_FOR = 12.months

  # -----------------------------------------------------------------------------

  self.table_name = 'listing_filters'
  self.primary_key = 'listing_filter_id'

  def id = listing_filter_id

  # -----------------------------------------------------------------------------

  # logs a listing load: listing_type (ex: 'Product / Sewing Kit', like Search's search_type), params (the filters and
  # sort applied), results (how many items it showed), search_id (the search the filters came straight from), and who
  # loaded it. nil when it's a repeat, or couldn't be saved, since failing to log doesn't fail the listing
  def self.log(listing_type:, params:, results:, search_id: nil, user_id: nil, user_session_token: nil, ip: nil)
    return if user_session_token.present? &&
      where(listing_type:, user_session_token:, created_at: REPEAT_WITHIN.ago..).where('params = ?::jsonb', params.to_json).exists?

    create!(listing_type:, params:, results:, search_id:, user_id:, user_session_token:, ip:)
  rescue => e
    CapturedException.log(location: 'ListingFilter.log', note: { listing_type:, params: }, e:)
    nil
  end

  # -----------------------------------------------------------------------------

end
