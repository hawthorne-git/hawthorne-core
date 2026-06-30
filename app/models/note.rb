class Note < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  has_many_attached :note_files

  # -----------------------------------------------------------------------------

  self.table_name = 'notes'
  self.primary_key = 'note_id'

  def id = note_id

  # -----------------------------------------------------------------------------

end
