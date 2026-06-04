class HawthorneCore::PageBlockType < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  has_one_attached :example_image

  # -----------------------------------------------------------------------------

  self.table_name = 'page_block_types'
  self.primary_key = 'page_block_type_id'

  def id = page_block_type_id

  # -----------------------------------------------------------------------------

end
