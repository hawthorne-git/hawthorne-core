class HawthorneCore::PageType < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'page_types'
  self.primary_key = 'page_type_id'

  def id = page_type_id

  # -----------------------------------------------------------------------------

end
