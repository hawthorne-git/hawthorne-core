class ImageAltTextJob < HawthorneCore::ApplicationJob

  queue_as :low

  # -----------------------------------------------------------------------------------------

  def perform(image_id: nil)
    model_prompt = AiModelPrompt
                     .joins(ai_prompt: :ai_prompt_type)
                     .where(default_prompt: true, deleted: false)
                     .where(ai_prompt_types: { handle: 'Image: Alt Text' })
                     .includes(:ai_model, :ai_prompt)
                     .first

    unless model_prompt
      Rails.logger.warn 'ImageAltTextJob no default model prompt found for Image: Alt Text'
      return
    end

    svc = Services::CaludeSvc.new

    images = if image_id
               HawthorneCore::Image.where(image_id: image_id, deleted: false)
             else
               HawthorneCore::Image
                 .where(deleted: false)
                 .where("alt_text IS NULL OR alt_text = ''")
                 .order(:image_id)
                 .limit(100)
             end

    images.each do |image|
      next if image.file_key.blank?

      image_url = "#{HawthorneCore::AppConfig.media_host}/#{image.file_key}"

      result = svc.image_alt_text(
        image_url: image_url,
        model_api: model_prompt.ai_model.api_handle,
        max_tokens: model_prompt.max_tokens,
        prompt: model_prompt.ai_prompt.prompt
      )

      input_cost = (result[:input_tokens] / 1_000_000.0) * model_prompt.ai_model.input_price_per_mtok
      output_cost = (result[:output_tokens] / 1_000_000.0) * model_prompt.ai_model.output_price_per_mtok

      AiGeneration.create!(
        ai_model_prompt_id: model_prompt.ai_model_prompt_id,
        item_type: 'HawthorneCore::Image',
        item_id: image.image_id,
        input_tokens: result[:input_tokens],
        output_tokens: result[:output_tokens],
        input_cost: input_cost,
        output_cost: output_cost,
        total_cost: input_cost + output_cost,
        raw_response: result.except(:input_tokens, :output_tokens)
      )

      image.update!(
        alt_text: result[:alt_text],
        alt_text_ai_model_prompt_id: model_prompt.id
      )

    rescue => e
      HawthorneCore::CapturedException.log(location: 'ImageAltTextJob', note: { image_id: image.image_id }, e:)
    end
  end

  # -----------------------------------------------------------------------------------------

end
