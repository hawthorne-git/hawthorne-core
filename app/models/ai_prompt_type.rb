class AiPromptType < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'ai_prompt_types'
  self.primary_key = 'ai_prompt_type_id'

  def id = ai_prompt_type_id

  # -----------------------------------------------------------------------------

end
