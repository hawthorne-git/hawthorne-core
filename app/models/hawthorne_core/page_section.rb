class HawthorneCore::PageSection < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'page_sections'
  self.primary_key = 'page_section_id'

  def id = page_section_id

  # -----------------------------------------------------------------------------

end
