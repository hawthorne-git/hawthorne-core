class Collection < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'collections'
  self.primary_key = 'collection_id'

  def id = collection_id

  # -----------------------------------------------------------------------------

end
