class HawthorneCore::AiPrompt < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'ai_prompts'
  self.primary_key = 'ai_prompt_id'

  def id = ai_prompt_id

  # -----------------------------------------------------------------------------

end
