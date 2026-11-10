module Ai
  # writes a product's search text: the words shoppers might search to find it, as labeled lines (see KINDS for the
  # product types written for, and each one's fields), from its name, supplier, attrs, description and supplier main
  # image's visual description (see ImageVisualDescriptionJob). text only, so it's cheap to write again. it's written
  # again only when what it's written from changes (see search_text_source_digest), or, when the model prompt updates
  # existing ones, when another model prompt wrote it. a product whose supplier main image is still waiting for its
  # visual description waits too (the description being written queues it, see Image). the model and instructions come
  # from the default AI model prompt of its kind's prompt type; each call is logged as an AiGeneration with its cost.
  # run without a product, it writes the next products in need
  class ProductSearchTextJob < HawthorneCore::ApplicationJob

    queue_as :low

    # a product type whose products get search text: prompt_type (the AI prompt type whose default model prompt writes
    # it), details (what Claude is given besides the name, supplier, description and main image, in order: an attr key
    # for a Select attr's option name, or :finished_size), fields (the answer's fields, in order, with their search
    # text labels; the prompt explains each field)
    Kind = Data.define(:prompt_type, :details, :fields)

    # keyed by the ProductType id method's name (ex: sewing_kit => ProductType.sewing_kit_id)
    KINDS = {
      sewing_kit: Kind.new(
        prompt_type: 'Product / Sewing Kit / Search Text',
        details: ['project', :finished_size, 'difficulty'],
        fields: {
          'themes' => 'Themes',
          'motifs' => 'Motifs',
          'colors' => 'Colors',
          'style' => 'Style',
          'project' => 'Project',
          'fabric_lines' => 'Fabric lines',
          'designers' => 'Designers',
          'also_known_as' => 'Also known as'
        }.freeze
      ),
      sample_card: Kind.new(
        prompt_type: 'Product / Sample Card / Search Text',
        details: ['type'],
        fields: {
          'brands' => 'Brands',
          'product_lines' => 'Product lines',
          'materials' => 'Materials',
          'features' => 'Features',
          'uses' => 'Uses',
          'colors' => 'Colors',
          'also_known_as' => 'Also known as'
        }.freeze
      )
    }.freeze

    EFFORT = :low

    # the most products written in one run without a product
    BATCH_SIZE = 100

    # the visual attrs (see ImageVisualDescriptionJob::SCHEMA) given with the image's description, with their labels
    VISUAL_FIELDS = {
      'colors' => 'colors',
      'palette' => 'palette',
      'motifs' => 'motifs',
      'patterns' => 'patterns',
      'themes' => 'themes',
      'style' => 'style',
      'visible_text' => 'text printed on it',
      'search_terms' => 'search terms'
    }.freeze

    # the product types whose products get search text (and so are embedded, see ProductEmbeddingJob)
    def self.product_type_ids = KINDS.keys.map { |key| ProductType.public_send("#{key}_id") }

    # -----------------------------------------------------------------------------------------

    def perform(product_id: nil)
      @option_handles = option_handles
      svc = Services::CaludeSvc.new
      written = 0

      KINDS.each do |key, kind|
        break if written >= BATCH_SIZE

        products = Product.active
                          .where(product_type_id: ProductType.public_send("#{key}_id"), update_search_text_with_ai: true)
                          .includes(:supplier, product_images: { image: :image_type })
                          .order(:product_id)
        products = products.where(product_id:) if product_id
        # a missing model prompt is only reported when there's a product of this kind to write
        next unless products.exists?

        model_prompt = model_prompt_for(kind)
        unless model_prompt
          CapturedException.log(location: 'Ai::ProductSearchTextJob', note: "no default model prompt found for #{kind.prompt_type}")
          next
        end

        schema = schema_for(kind)

        products.each do |product|
          break if written >= BATCH_SIZE
          next if waiting_for_image?(product)

          source = source_text(product, kind)
          digest = Digest::SHA256.hexdigest(source)
          next unless needs_writing?(product, digest, model_prompt)

          written += 1
          result = svc.json_answer(
            model_api: model_prompt.ai_model.api_handle,
            effort: EFFORT,
            max_tokens: model_prompt.max_tokens,
            instructions: model_prompt.ai_prompt.prompt,
            text: source,
            schema: schema
          )

          input_cost = (result[:input_tokens] / 1_000_000.0) * model_prompt.ai_model.input_price_per_mtok
          output_cost = (result[:output_tokens] / 1_000_000.0) * model_prompt.ai_model.output_price_per_mtok

          AiGeneration.create!(
            ai_model_prompt_id: model_prompt.ai_model_prompt_id,
            item_type: 'Product',
            item_id: product.product_id,
            input_tokens: result[:input_tokens],
            output_tokens: result[:output_tokens],
            input_cost: input_cost,
            output_cost: output_cost,
            total_cost: input_cost + output_cost,
            raw_response: result.except(:input_tokens, :output_tokens)
          )

          # saved again in case the product changed while Claude was asked (ex: the search text was edited by hand)
          product.reload
          next unless product.update_search_text_with_ai?

          # the version history shows this job wrote it
          PaperTrail.request(whodunnit: self.class.name, controller_info: { whodunnit_type: 'Job' }) do
            product.update!(
              search_text: search_text(result[:answer], kind),
              search_text_source_digest: digest,
              search_text_ai_model_prompt_id: model_prompt.ai_model_prompt_id
            )
          end

        rescue => e
          CapturedException.log(location: 'Ai::ProductSearchTextJob', note: { product_id: product.product_id }, e:)
        end
      end

      nil
    end

    # -----------------------------------------------------------------------------------------

    private

    # the kind's prompt type's default AI model prompt (nil when there isn't one)
    def model_prompt_for(kind)
      AiModelPrompt
        .joins(ai_prompt: :ai_prompt_type)
        .where(default_prompt: true, deleted: false)
        .where(ai_prompt_types: { handle: kind.prompt_type })
        .includes(:ai_model, :ai_prompt)
        .first
    end

    # the answer's shape: a list of words / phrases per field
    def schema_for(kind)
      {
        type: 'object',
        properties: kind.fields.keys.to_h { |field| [field.to_sym, { type: 'array', items: { type: 'string' } }] },
        required: kind.fields.keys,
        additionalProperties: false
      }
    end

    # whether the product's supplier main image is still waiting for its visual description (one that AI won't
    # describe, ex: its description was cleared by hand, doesn't hold the product up)
    def waiting_for_image?(product)
      image = product.supplier_main_image
      image.present? && image.visual_description.blank? && image.update_visual_description_with_ai?
    end

    # written when there's none yet, what it's written from changed, or the model prompt updates ones another wrote
    def needs_writing?(product, digest, model_prompt)
      product.search_text.blank? ||
        product.search_text_source_digest != digest ||
        (model_prompt.update_existing? && product.search_text_ai_model_prompt_id != model_prompt.ai_model_prompt_id)
    end

    # what Claude is given: the product's details as labeled lines (ones without a value left out)
    def source_text(product, kind)
      image = product.supplier_main_image
      visual = image&.visual_attrs || {}
      lines = [
        ['Name', product.handle],
        ['Supplier', product.supplier&.handle],
        *kind.details.map { |detail| detail_line(product, detail) },
        ['Description', product.description.to_s.squish.presence],
        ['Main image', image&.visual_description.to_s.squish.presence]
      ]
      lines += VISUAL_FIELDS.map { |field, label| ["Main image #{label}", Array(visual[field]).join(', ').presence] }
      lines.select { |_, value| value.present? }.map { |label, value| "#{label}: #{value}" }.join("\n")
    end

    # a detail's label and value (ex: ['Difficulty', 'Confident Beginner'])
    def detail_line(product, detail)
      return ['Finished size', finished_size(product)] if detail == :finished_size
      [detail.humanize, option_label(product, detail)]
    end

    # the answer as labeled lines, leaving out empty fields (ex: "Themes: autumn, fall")
    def search_text(answer, kind)
      kind.fields.filter_map do |field, label|
        values = Array(answer[field]).map { |value| value.to_s.squish }.compact_blank.uniq
        "#{label}: #{values.join(', ')}" if values.any?
      end.join("\n")
    end

    # a Select attr's option name (ex: 'confident_beginner' => 'Confident Beginner'), or the value humanized when it's
    # no longer an option; nil when it isn't set
    def option_label(product, key)
      value = product.attr_value(key)
      return if value.blank?
      @option_handles.dig(product.product_type_id, key, value) || value.to_s.humanize
    end

    # the width x length in inches (ex: 61" x 69"); nil without a width
    def finished_size(product)
      width, length = [product.attr_value('width'), product.attr_value('length')].map { |inches| inches_text(inches) }
      return if width.nil?
      length ? "#{width} x #{length}" : "#{width} wide"
    end

    def inches_text(inches)
      return unless inches.is_a?(Numeric)
      "#{(inches % 1).zero? ? inches.to_i : inches}\""
    end

    # the kinds' attrs' active options: product_type_id => { key => { value => handle } }
    def option_handles
      ProductTypeAttr.includes(:product_attr, :product_type_attr_options)
                     .where(product_type_id: self.class.product_type_ids)
                     .group_by(&:product_type_id)
                     .transform_values do |type_attrs|
                       type_attrs.to_h do |type_attr|
                         [type_attr.key, type_attr.product_type_attr_options.select(&:active?).to_h { |option| [option.value, option.handle] }]
                       end
                     end
    end

    # -----------------------------------------------------------------------------------------

  end
end
