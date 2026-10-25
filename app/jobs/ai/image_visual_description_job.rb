module Ai
  # describes a supplier main image (see Product::SUPPLIER_MAIN_IMAGE_TYPE) in detail for product search: its colors,
  # motifs, patterns, themes, style and printed text, from the image alone. the summary is the visual description, and
  # the whole answer is kept as its visual attrs. the model and instructions come from the default AI model prompt of
  # the PROMPT_TYPE prompt type; each call is logged as an AiGeneration with its cost. queued as a supplier main image's
  # file is uploaded or replaced (see Image); run without an image, it describes the next images in need (ones without
  # a description, or, when the model prompt updates existing ones, ones described by another model prompt)
  class ImageVisualDescriptionJob < HawthorneCore::ApplicationJob

    queue_as :low

    PROMPT_TYPE = 'Image / Visual Description'

    # the most images described in one run without an image
    BATCH_SIZE = 100

    # the answer's shape (the prompt explains each field)
    LIST = { type: 'array', items: { type: 'string' } }.freeze
    SCHEMA = {
      type: 'object',
      properties: {
        summary: { type: 'string' },
        item_type: { type: 'string' },
        colors: LIST,
        palette: LIST,
        motifs: LIST,
        patterns: LIST,
        themes: LIST,
        style: LIST,
        visible_text: LIST,
        search_terms: LIST
      },
      required: %w[summary item_type colors palette motifs patterns themes style visible_text search_terms],
      additionalProperties: false
    }.freeze

    # -----------------------------------------------------------------------------------------

    def perform(image_id: nil)
      model_prompt = AiModelPrompt
                       .joins(ai_prompt: :ai_prompt_type)
                       .where(default_prompt: true, deleted: false)
                       .where(ai_prompt_types: { handle: PROMPT_TYPE })
                       .includes(:ai_model, :ai_prompt)
                       .first

      unless model_prompt
        CapturedException.log(location: 'Ai::ImageVisualDescriptionJob', note: "no default model prompt found for #{PROMPT_TYPE}")
        return
      end

      svc = Services::CaludeSvc.new

      base = Image.joins(:image_type)
                  .where(deleted: false, update_visual_description_with_ai: true)
                  .where(image_types: { handle: Product::SUPPLIER_MAIN_IMAGE_TYPE })
                  .where.not(file_key: [nil, ''])
      images = if image_id
                 base.where(image_id:)
               elsif model_prompt.update_existing?
                 base.where('visual_description_ai_model_prompt_id IS DISTINCT FROM ?', model_prompt.ai_model_prompt_id)
                     .order(:image_id).limit(BATCH_SIZE)
               else
                 base.where("visual_description IS NULL OR visual_description = ''").order(:image_id).limit(BATCH_SIZE)
               end

      images.each do |image|
        result = svc.image_json_answer(
          image_url: "#{HawthorneCore::AppConfig.media_host}/#{image.file_key}",
          model_api: model_prompt.ai_model.api_handle,
          max_tokens: model_prompt.max_tokens,
          instructions: model_prompt.ai_prompt.prompt,
          schema: SCHEMA
        )

        input_cost = (result[:input_tokens] / 1_000_000.0) * model_prompt.ai_model.input_price_per_mtok
        output_cost = (result[:output_tokens] / 1_000_000.0) * model_prompt.ai_model.output_price_per_mtok

        AiGeneration.create!(
          ai_model_prompt_id: model_prompt.ai_model_prompt_id,
          item_type: 'Image',
          item_id: image.image_id,
          input_tokens: result[:input_tokens],
          output_tokens: result[:output_tokens],
          input_cost: input_cost,
          output_cost: output_cost,
          total_cost: input_cost + output_cost,
          raw_response: result.except(:input_tokens, :output_tokens)
        )

        # saved again in case the image changed while Claude was asked (ex: the description was edited by hand)
        image.reload
        next unless image.update_visual_description_with_ai?

        # the version history shows this job wrote it
        PaperTrail.request(whodunnit: self.class.name, controller_info: { whodunnit_type: 'Job' }) do
          image.update!(
            visual_description: result[:answer]['summary'].to_s.strip,
            visual_attrs: result[:answer],
            visual_description_ai_model_prompt_id: model_prompt.ai_model_prompt_id
          )
        end

      rescue => e
        CapturedException.log(location: 'Ai::ImageVisualDescriptionJob', note: { image_id: image.image_id }, e:)
      end

      nil
    end

    # -----------------------------------------------------------------------------------------

  end
end
