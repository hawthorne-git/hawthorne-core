class AiModel < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'ai_models'
  self.primary_key = 'ai_model_id'

  def id = ai_model_id

  # -----------------------------------------------------------------------------

end
