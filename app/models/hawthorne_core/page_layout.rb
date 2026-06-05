class HawthorneCore::PageLayout < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'page_layouts'
  self.primary_key = 'page_layout_id'

  def id = page_layout_id

  # -----------------------------------------------------------------------------

end
