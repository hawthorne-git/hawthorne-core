class AiModelPrompt < HawthorneCore::ActiveRecordBaseAdmin

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'ai_model_prompts'
  self.primary_key = 'ai_model_prompt_id'

  def id = ai_model_prompt_id

  # -----------------------------------------------------------------------------

  belongs_to :ai_model, class_name: 'AiModel'
  belongs_to :ai_prompt, class_name: 'AiPrompt'

  # -----------------------------------------------------------------------------

end
