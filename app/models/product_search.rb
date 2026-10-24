# turns what a shopper types in a listing's search box (ex: "an easy quilt kit under $100") into the listing's params
# (see ProductFilter), by asking Claude to pick from the listing's filter options. words that aren't an option (ex:
# "christmas", "batik") come back as keywords, matched against the products' names and descriptions. the model, max
# tokens and instructions come from the default AI model prompt of the PROMPT_TYPE prompt type (the listing's options
# are added to the instructions here); each call is logged as an AiGeneration with its cost. answers are cached by
# search; when Claude can't answer (ex: no model prompt, an error or a timeout), the search's own words are the keywords
class ProductSearch

  PROMPT_TYPE = 'Product / Sewing Kit / Search'

  EFFORT = :low

  # seconds to wait for Claude before falling back to keywords
  TIMEOUT = 15

  CACHE_FOR = 30.days

  # the longest search kept, in characters
  MAX_LENGTH = 200

  # words left out of the fallback keywords, since they'd match nothing or everything
  STOP_WORDS = %w[
    about all an and any are around but can easy fabric find for from have i'm im kit kits like looking made make me more
    my need not of one or pattern project quilt sew sewing show simple size some something than that the this to too
    under over use using very want with would
  ].freeze

  # the type value the answer uses for no type
  ANY_TYPE = 'any'

  # the stock value the answer uses for either
  ANY_STOCK = 'any'

  # -----------------------------------------------------------------------------

  # text: what the shopper typed
  # filter: a ProductFilter for the whole listing (nothing selected or searched), whose options the search picks from
  def initialize(text, filter:)
    @text = text.to_s.squish.first(MAX_LENGTH)
    @filter = filter
  end

  # the listing's params for this search: search (the text, shown in the search box), plus the filters, price limits
  # and keywords it asked for
  def params
    answer = (cached_answer if @text.present?) || fallback_answer
    {
      search: @text,
      keywords: answer['keywords'],
      type: [answer['type']].compact - [ANY_TYPE],
      size: answer['sizes'],
      difficulty: answer['difficulties'],
      supplier: answer['suppliers'],
      stock: [answer['stock']].compact - [ANY_STOCK]
    }.merge(price_params(answer['min_price'], answer['max_price'])).compact_blank
  end

  # -----------------------------------------------------------------------------

  private

  # Claude's answer for this search (nil when it can't answer); the same search with the same model prompt and options
  # is answered once, then served from the cache
  def cached_answer
    unless model_prompt
      CapturedException.log(location: 'ProductSearch', note: "no default model prompt found for #{PROMPT_TYPE}")
      return
    end

    version = [model_prompt.ai_model_prompt_id, model_prompt.ai_model.api_handle, model_prompt.max_tokens, EFFORT,
               instructions, schema.to_json].join(' ')
    key = ['product-search', Digest::SHA256.hexdigest(version), @text.downcase]
    Rails.cache.fetch(key, expires_in: CACHE_FOR, skip_nil: true) { ask_claude }
  end

  def ask_claude
    result = Services::CaludeSvc.new.json_answer(
      model_api: model_prompt.ai_model.api_handle,
      effort: EFFORT,
      max_tokens: model_prompt.max_tokens,
      instructions: instructions,
      text: "The shopper's search: #{@text}",
      schema: schema,
      timeout: TIMEOUT
    )
    log_generation(result)
    result[:answer]
  rescue => e
    CapturedException.log(location: 'ProductSearch', note: { text: @text }, e:)
    nil
  end

  # logs the call and its cost, whether or not the answer is used; failing to log doesn't fail the search. item_id is
  # 0 until searches are saved, when it becomes the search's row
  def log_generation(result)
    ai_model = model_prompt.ai_model
    input_cost = (result[:input_tokens] / 1_000_000.0) * ai_model.input_price_per_mtok
    output_cost = (result[:output_tokens] / 1_000_000.0) * ai_model.output_price_per_mtok

    AiGeneration.create!(
      ai_model_prompt_id: model_prompt.ai_model_prompt_id,
      item_type: 'ProductSearch',
      item_id: 0,
      input_tokens: result[:input_tokens],
      output_tokens: result[:output_tokens],
      input_cost: input_cost,
      output_cost: output_cost,
      total_cost: input_cost + output_cost,
      raw_response: { search: @text, answer: result[:answer], model: result[:model] }
    )
  rescue => e
    CapturedException.log(location: 'ProductSearch#log_generation', note: { text: @text }, e:)
  end

  # the PROMPT_TYPE prompt type's default AI model prompt (nil when there isn't one)
  def model_prompt
    return @model_prompt if defined?(@model_prompt)
    @model_prompt = AiModelPrompt
                      .joins(ai_prompt: :ai_prompt_type)
                      .where(default_prompt: true, deleted: false)
                      .where(ai_prompt_types: { handle: PROMPT_TYPE })
                      .includes(:ai_model, :ai_prompt)
                      .first
  end

  # the search's price limits: on the price ranges' edges (ex: under $100, over $150), the ranges they cover, so they
  # show as the price range filter; otherwise (ex: under $90) the exact limits
  def price_params(min, max)
    min = nil unless min&.positive?
    max = nil unless max&.positive?
    return {} if min.nil? && max.nil?

    edges = ProductFilter::PRICE_RANGES.values.flat_map { |(_, low, high)| [low, high] }.compact
    return { min_price: min, max_price: max } unless [min, max].compact.all? { |price| edges.include?(price) }

    ranges = ProductFilter::PRICE_RANGES.select do |_, (_, low, high)|
      (min.nil? || (low && low >= min)) && (max.nil? || (high && high <= max))
    end
    { price: ranges.keys }
  end

  # the search's own words as keywords, for when Claude can't answer: each as typed, or singular when only that is in a
  # product's name or description (ex: fabrics => fabric), leaving out short and generic words, and words in no
  # product's name or description (ex: difficult), so one stray word doesn't empty the listing
  def fallback_answer
    texts = @filter.products.map { |product| "#{product.handle} #{product.description}".downcase }
    words = @text.downcase.scan(/[[:alnum:]']+/).filter_map do |word|
      [word, word.delete_suffix('s')].find { |form| texts.any? { |text| text.include?(form) } }
    end
    words = words.reject do |word|
      word.size < 3 || word.match?(/\A\d+\z/) || STOP_WORDS.include?(word) || STOP_WORDS.include?(word.delete_suffix('s'))
    end
    { 'keywords' => words.uniq.first(ProductFilter::MAX_KEYWORDS) }
  end

  # the answer's shape: only the listing's options can be picked
  def schema
    @schema ||= begin
      properties = {
        keywords: { type: 'array', items: { type: 'string' } },
        min_price: { anyOf: [{ type: 'number' }, { type: 'null' }] },
        max_price: { anyOf: [{ type: 'number' }, { type: 'null' }] },
        stock: { type: 'string', enum: ProductFilter::STOCK_STATUSES.keys + [ANY_STOCK] }
      }
      properties[:type] = { type: 'string', enum: @filter.types + [ANY_TYPE] } if @filter.type_filter?
      properties[:sizes] = { type: 'array', items: { type: 'string', enum: ProductFilter::QUILT_SIZES.keys } } if @filter.quilt_sizes?
      properties[:difficulties] = { type: 'array', items: { type: 'string', enum: @filter.difficulties } } if @filter.difficulty_filter?
      properties[:suppliers] = { type: 'array', items: { type: 'string', enum: @filter.suppliers.map(&:token) } } if @filter.suppliers.any?
      { type: 'object', properties: properties, required: properties.keys, additionalProperties: false }
    end
  end

  # what Claude is told: the model prompt's instructions (its job, and how to read common phrases), then the listing's
  # options
  def instructions
    @instructions ||= [
      model_prompt.ai_prompt.prompt.strip,
      "The store's options:\n",
      (option_list("Type (pick one, or \"#{ANY_TYPE}\")", @filter.types.map { |value| [value, @filter.type_label(value)] }) if @filter.type_filter?),
      (option_list('Quilt size (only for quilts; pick every size that fits), by the quilt\'s width', quilt_size_options) if @filter.quilt_sizes?),
      (option_list('Difficulty (pick every level that fits)', @filter.difficulties.map { |value| [value, @filter.difficulty_label(value)] }) if @filter.difficulty_filter?),
      (option_list('Supplier (pick every one the shopper names)', @filter.suppliers.map { |supplier| [supplier.token, supplier.handle] }) if @filter.suppliers.any?),
      option_list("Stock (pick one, or \"#{ANY_STOCK}\")", ProductFilter::STOCK_STATUSES.to_a)
    ].compact.join("\n")
  end

  def option_list(heading, options)
    "#{heading}:\n#{options.map { |value, label| "- #{value}: #{label}" }.join("\n")}\n"
  end

  # the quilt sizes with their widths (ex: Lap & Throw, 50" to 68" wide)
  def quilt_size_options
    ProductFilter::QUILT_SIZES.map do |key, (label, min, max)|
      width = if min.nil? then "under #{max}\" wide"
              elsif max.nil? then "#{min}\" wide and up"
              else "#{min}\" to #{max}\" wide"
              end
      [key, "#{label} (#{width})"]
    end
  end

end
