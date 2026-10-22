module Ai
  # sets a sewing kit's Project attr (ex: quilt, table runner) from its supplier main image, asking Jev which of the
  # Project options (Sewing Kit's active ones, so adding an option needs no code change) the cover image shows. the
  # model and instructions come from the default AI model prompt of the PROMPT_TYPE prompt type; each call is logged as
  # an AiGeneration with its cost. only a kit with no Project set is classified, and an image is only asked about once
  # per model prompt; a low confidence / probability answer leaves it unset (Unknown), to be set on the form
  class SewingKitProjectJob < HawthorneCore::ApplicationJob

    queue_as :low

    # TypeSafe timing out, rate limiting or erroring is tried again (waiting longer each time); after the last attempt
    # it's logged, and the kit is asked about again on its next save
    retry_on Services::TypeSafeSvc::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
      CapturedException.log(location: 'Ai::SewingKitProjectJob', note: { product_id: job.arguments.first[:product_id], attempts: 5 }, e: error)
    end

    PROJECT_KEY = 'project'

    # Jev's answer is set only when it's sure enough: its confidence, and the probability it gives its own choice (from
    # the answer's probabilities), must both be at least these
    MIN_CONFIDENCE = 0.8
    MIN_PROBABILITY = 0.75

    PROMPT_TYPE = 'Product / Sewing Kit / Project'

    # -----------------------------------------------------------------------------------------

    def perform(product_id:)
      product = Product.includes(product_images: { image: [:image_type, { file_attachment: :blob }] }).find_by(product_id:)
      return unless product&.project_classifiable?

      image = product.supplier_main_image
      return unless image&.file&.attached?

      options = project_options
      return if options.empty?

      model_prompt = AiModelPrompt
                       .joins(ai_prompt: :ai_prompt_type)
                       .where(default_prompt: true, deleted: false)
                       .where(ai_prompt_types: { handle: PROMPT_TYPE })
                       .includes(:ai_model, :ai_prompt)
                       .first

      unless model_prompt
        CapturedException.log(location: 'Ai::SewingKitProjectJob', note: "no default model prompt found for #{PROMPT_TYPE}")
        return
      end

      # Jev answers the same image and prompt the same way, so one already asked about isn't asked again (ex: a kit
      # saved again whose answer was too unsure to set, or the save and image triggers both queuing this job)
      return if AiGeneration.exists?(ai_model_prompt_id: model_prompt.ai_model_prompt_id, item_type: 'Image', item_id: image.image_id)

      # the product name goes with the image (the cover images share one template, so the name tells a table runner
      # from a quilt)
      result = Services::TypeSafeSvc.new.image_choice(
        model_api: model_prompt.ai_model.api_handle,
        image_bytes: image.file.download,
        instructions: model_prompt.ai_prompt.prompt,
        criteria: options.to_h { |option| [option.value, option.handle] },
        context: "Product name: #{product.handle}"
      )

      # logged whether or not the answer is used
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

      answer = result[:answer]
      choice = answer['choice']
      return unless options.any? { |option| option.value == choice }
      return unless answer['confidence'].to_f >= MIN_CONFIDENCE && answer.dig('probabilities', choice).to_f >= MIN_PROBABILITY

      # saved again in case the kit changed while Jev was asked (ex: a Project was set on the form)
      product.reload
      return unless product.project_classifiable?

      # the version history shows this job set it
      PaperTrail.request(whodunnit: self.class.name, controller_info: { whodunnit_type: 'Job' }) do
        product.update!(attrs: (product.attrs || {}).merge(PROJECT_KEY => choice))
      end

    rescue Services::TypeSafeSvc::TransientError
      raise
    rescue => e
      CapturedException.log(location: 'Ai::SewingKitProjectJob', note: { product_id:, answer: }, e:)
    end

    # -----------------------------------------------------------------------------------------

    private

    # Sewing Kit's active Project options, in order (none when Sewing Kit has no Project attr)
    def project_options
      type_attr = ProductType.find(ProductType.sewing_kit_id).product_type_attrs.includes(:product_attr, :product_type_attr_options)
                             .find { |product_type_attr| product_type_attr.key == PROJECT_KEY }
      type_attr ? type_attr.product_type_attr_options.select(&:active?) : []
    end

    # -----------------------------------------------------------------------------------------

  end
end
