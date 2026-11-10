module Ai
  # summarizes a sample card's pdf (see Product::SAMPLE_CARD_DOCUMENT_TYPE; ex: a maker's color card) for product
  # search: its brands, product lines, materials, color families and shades, from the pdf alone. the summary is kept as
  # the document's summary, and the whole answer as its summary attrs (see ProductSearchTextJob, which writes a sample
  # card's search text from them). the model and instructions come from the default AI model prompt of the
  # PROMPT_TYPE prompt type; each call is logged as an AiGeneration with its cost. queued as a sample card pdf's file is
  # stored or replaced (see Document); run without a document, it summarizes the next documents in need (ones without
  # a summary, or, when the model prompt updates existing ones, ones summarized by another model prompt)
  class DocumentSummaryJob < HawthorneCore::ApplicationJob

    queue_as :low

    PROMPT_TYPE = 'Document / Sample Card / Summary'

    # the most documents summarized in one run without a document
    BATCH_SIZE = 25

    # the answer's shape (the prompt explains each field)
    LIST = { type: 'array', items: { type: 'string' } }.freeze
    SCHEMA = {
      type: 'object',
      properties: {
        summary: { type: 'string' },
        brands: LIST,
        product_lines: LIST,
        materials: LIST,
        color_families: LIST,
        shades: {
          type: 'array',
          items: {
            type: 'object',
            properties: { number: { type: 'string' }, name: { type: 'string' } },
            required: %w[number name],
            additionalProperties: false
          }
        },
        search_terms: LIST
      },
      required: %w[summary brands product_lines materials color_families shades search_terms],
      additionalProperties: false
    }.freeze

    # -----------------------------------------------------------------------------------------

    def perform(document_id: nil)
      base = Document.active
                     .joins(:document_type)
                     .where(update_summary_with_ai: true)
                     .where(document_types: { handle: Product::SAMPLE_CARD_DOCUMENT_TYPE })
                     .where.not(file_key: [nil, ''])
      # a missing model prompt is only reported when there's a document to summarize
      return unless base.exists?

      model_prompt = AiModelPrompt
                       .joins(ai_prompt: :ai_prompt_type)
                       .where(default_prompt: true, deleted: false)
                       .where(ai_prompt_types: { handle: PROMPT_TYPE })
                       .includes(:ai_model, :ai_prompt)
                       .first

      unless model_prompt
        CapturedException.log(location: 'Ai::DocumentSummaryJob', note: "no default model prompt found for #{PROMPT_TYPE}")
        return
      end

      svc = Services::CaludeSvc.new

      documents = if document_id
                    base.where(document_id:)
                  elsif model_prompt.update_existing?
                    base.where('summary_ai_model_prompt_id IS DISTINCT FROM ?', model_prompt.ai_model_prompt_id)
                        .order(:document_id).limit(BATCH_SIZE)
                  else
                    base.where("summary IS NULL OR summary = ''").order(:document_id).limit(BATCH_SIZE)
                  end

      documents.each do |document|
        result = svc.pdf_json_answer(
          pdf_url: "#{HawthorneCore::AppConfig.media_host}/#{document.file_key}?v=#{document.file_version}",
          model_api: model_prompt.ai_model.api_handle,
          max_tokens: model_prompt.max_tokens,
          instructions: model_prompt.ai_prompt.prompt,
          schema: SCHEMA
        )

        input_cost = (result[:input_tokens] / 1_000_000.0) * model_prompt.ai_model.input_price_per_mtok
        output_cost = (result[:output_tokens] / 1_000_000.0) * model_prompt.ai_model.output_price_per_mtok

        AiGeneration.create!(
          ai_model_prompt_id: model_prompt.ai_model_prompt_id,
          item_type: 'Document',
          item_id: document.document_id,
          input_tokens: result[:input_tokens],
          output_tokens: result[:output_tokens],
          input_cost: input_cost,
          output_cost: output_cost,
          total_cost: input_cost + output_cost,
          raw_response: result.except(:input_tokens, :output_tokens)
        )

        # saved again in case the document changed while Claude was asked (ex: the summary was edited by hand)
        document.reload
        next unless document.update_summary_with_ai?

        # the version history shows this job wrote it
        PaperTrail.request(whodunnit: self.class.name, controller_info: { whodunnit_type: 'Job' }) do
          document.update!(
            summary: result[:answer]['summary'].to_s.strip,
            summary_attrs: result[:answer],
            summary_ai_model_prompt_id: model_prompt.ai_model_prompt_id
          )
        end

      rescue => e
        CapturedException.log(location: 'Ai::DocumentSummaryJob', note: { document_id: document.document_id }, e:)
      end

      nil
    end

    # -----------------------------------------------------------------------------------------

  end
end
