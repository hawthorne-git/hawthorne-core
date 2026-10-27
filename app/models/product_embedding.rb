# what a product means, as an embedding of its name and search text (see Ai::ProductEmbeddingJob), one per product and
# embedding model. products whose embeddings are close are alike (see Product#similar_products); embeddings are only
# compared with ones from the same model
class ProductEmbedding < ActiveRecordBaseApp

  # the prompt type whose default AI model prompt sets the embedding model (the prompt itself isn't sent: embeddings
  # have no instructions), and that the embeddings' costs are logged against
  PROMPT_TYPE = 'Product / Embedding'

  # -----------------------------------------------------------------------------

  self.table_name = 'product_embeddings'
  self.primary_key = 'product_embedding_id'

  def id = product_embedding_id

  # -----------------------------------------------------------------------------

  belongs_to :product

  # -----------------------------------------------------------------------------

  # the PROMPT_TYPE prompt type's default AI model prompt (nil when there isn't one)
  def self.model_prompt
    AiModelPrompt.joins(ai_prompt: :ai_prompt_type)
                 .where(default_prompt: true, deleted: false)
                 .where(ai_prompt_types: { handle: PROMPT_TYPE })
                 .includes(:ai_model)
                 .first
  end

  # the embedding model in use (ex: 'voyage-3.5'; nil without a model prompt)
  def self.model_api = model_prompt&.ai_model&.api_handle

  # an embedding in pgvector's text form (ex: '[0.1,-0.2]'), to save in the embedding column
  def self.vector_literal(numbers) = "[#{numbers.map { |number| Float(number) }.join(',')}]"

end
