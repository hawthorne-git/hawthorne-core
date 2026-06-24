class AiGeneration < HawthorneCore::ActiveRecordBaseLog

  include HawthorneCore::CanBeSoftDeleted

  # -----------------------------------------------------------------------------

  self.table_name = 'ai_generations'
  self.primary_key = 'ai_generation_id'

  def id = ai_generation_id

  # -----------------------------------------------------------------------------

end
