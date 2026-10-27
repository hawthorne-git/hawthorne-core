module Ai
  # embeds what a sewing kit means (its name and search text, see ProductSearchTextJob) with the embedding model of
  # ProductEmbedding::PROMPT_TYPE's default AI model prompt, saved as its ProductEmbedding. a kit is embedded again only
  # when that text changes (see product_embeddings.source_digest), and every kit is embedded again when the model
  # changes (embeddings are kept per model). kits are embedded BATCH_SIZE to a request, and each request is logged as
  # an AiGeneration with its cost (item_id the product when there's one, else 0, with the products in raw_response).
  # queued as a kit's search text or name changes (see Product); run without a product, it embeds the kits in need
  class ProductEmbeddingJob < HawthorneCore::ApplicationJob

    queue_as :low

    # the most kits embedded in one request
    BATCH_SIZE = 50

    # the most kits embedded in one run without a product
    MAX_PER_RUN = 500

    # -----------------------------------------------------------------------------------------

    def perform(product_id: nil)
      model_prompt = ProductEmbedding.model_prompt

      unless model_prompt
        CapturedException.log(location: 'Ai::ProductEmbeddingJob', note: "no default model prompt found for #{ProductEmbedding::PROMPT_TYPE}")
        return
      end

      model = model_prompt.ai_model.api_handle
      products = Product.active
                        .where(product_type_id: ProductType.sewing_kit_id)
                        .where.not(search_text: [nil, ''])
                        .order(:product_id)
      products = products.where(product_id:) if product_id
      digests = ProductEmbedding.where(model:, product_id: products.select(:product_id)).pluck(:product_id, :source_digest).to_h

      needed = products.filter_map do |product|
        text = source_text(product)
        digest = Digest::SHA256.hexdigest(text)
        [product, text, digest] unless digests[product.product_id] == digest
      end

      svc = Services::VoyageSvc.new
      needed.first(MAX_PER_RUN).each_slice(BATCH_SIZE) do |batch|
        product_ids = batch.map { |product, _, _| product.product_id }
        result = svc.embed(texts: batch.map { |_, text, _| text }, model_api: model, input_type: 'document')

        input_cost = (result[:total_tokens] / 1_000_000.0) * model_prompt.ai_model.input_price_per_mtok
        AiGeneration.create!(
          ai_model_prompt_id: model_prompt.ai_model_prompt_id,
          item_type: 'Product',
          item_id: product_ids.one? ? product_ids.first : 0,
          input_tokens: result[:total_tokens],
          output_tokens: 0,
          input_cost: input_cost,
          output_cost: 0,
          total_cost: input_cost,
          raw_response: { model:, product_ids:, total_tokens: result[:total_tokens] }
        )

        rows = batch.zip(result[:embeddings]).map do |(product, _, digest), embedding|
          { product_id: product.product_id, model:, embedding: ProductEmbedding.vector_literal(embedding), source_digest: digest }
        end
        ProductEmbedding.upsert_all(rows, unique_by: :product_embeddings_uk_product_id_model)

      rescue => e
        CapturedException.log(location: 'Ai::ProductEmbeddingJob', note: { product_ids: }, e:)
      end

      nil
    end

    # -----------------------------------------------------------------------------------------

    private

    # what's embedded: the kit's name, then its search text (its themes, motifs, colors, style, ...)
    def source_text(product) = "#{product.handle}\n#{product.search_text}"

    # -----------------------------------------------------------------------------------------

  end
end
