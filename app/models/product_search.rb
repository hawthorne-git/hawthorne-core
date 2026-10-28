# turns what a shopper types in a listing's search box (ex: "an easy quilt kit under $100") into the listing's params
# (see ProductFilter), by asking Claude to pick from the listing's filter options. words that aren't an option (ex:
# "christmas", "batik") come back as keywords, each with a few related words that can match instead (ex: ocean =>
# nautical, beach), matched against the products' names, search text and descriptions. the model, max tokens and
# instructions come from the default AI model prompt of the PROMPT_TYPE prompt type (the listing's options
# are added to the instructions here). answers are cached by search; when Claude can't answer (ex: no model prompt, an
# error or a timeout), the search's own words are the keywords. each search is saved (see Search) with how it was
# answered, and each call to Claude is logged as an AiGeneration with its cost, pointing at the search
class ProductSearch

  PROMPT_TYPE = 'Product / Sewing Kit / Search'

  # the saved search's search_type
  SEARCH_TYPE = 'Product / Sewing Kit'

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

  # the sort value the answer uses when the shopper doesn't ask for one, so the listing's current sort is kept
  ANY_SORT = 'any'

  # the fewest letters / digits a search naming a product by its SKU / GTIN has (and a SKU's number must be)
  MIN_SKU_DIGITS = 5

  # the answer's quilt width / length limits, in inches (the same names as ProductFilter's params)
  QUILT_SIZE_LIMITS = %w[min_width max_width min_length max_length].freeze

  # how to add related words to the keywords (see ProductFilter::RELATED_SEPARATOR): kits described in other words than
  # the shopper's are found too
  KEYWORDS_NOTE = <<~NOTE
    Keywords (keywords): each keyword is an object with the word and its related words. For each keyword, add up to
    #{ProductFilter::MAX_RELATED_WORDS} related words a kit matching it might be described with instead: synonyms and closely related themes or
    motifs (ex: "ocean" has related words "nautical", "beach", "seaside", "sailboat"; "baby" has "nursery", "crib",
    "baby shower"). Stay close to the keyword's meaning and don't broaden it (ex: "blue" is too broad for "ocean"). A
    proper name (a fabric line, designer, brand, character or story) gets no related words. Use lowercase and the
    singular, as for the keywords.
  NOTE

  # how to read the shopper asking for kits on sale (see ProductFilter's sale param)
  ON_SALE_NOTE = <<~NOTE
    On sale (on_sale): true only when the shopper asks for kits on sale, such as "on sale", "sale", "discounted",
    "marked down", "clearance", "deals" or "bargains"; otherwise false. A price limit can go with it (ex: "on sale under
    $100" is on_sale true and max_price 100). "cheap" or "affordable" alone is not on sale.
  NOTE

  # -----------------------------------------------------------------------------

  # text: what the shopper typed
  # filter: a ProductFilter for the whole listing (nothing selected or searched), whose options the search picks from
  # user_id, user_session_token, ip: who searched, saved with the search
  # voice: whether the shopper spoke the search (voice search) rather than typed it, saved with the search
  def initialize(text, filter:, user_id: nil, user_session_token: nil, ip: nil, voice: false)
    @text = text.to_s.squish.first(MAX_LENGTH)
    @filter = filter
    @shopper = { user_id:, user_session_token:, ip: }
    @voice = voice
  end

  # the listing's params for this search: search (the text, shown in the search box), plus the filters, price limits,
  # quilt width / length limits and keywords it asked for. the search is saved (when there is one) with how long it
  # took to answer, then Claude's call (when it was asked) is logged
  def params
    return @params if defined?(@params)

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    answer = cached_answer if @text.present?
    answered_by = if answer.nil? then Search::ANSWERED_BY_FALLBACK
                  elsif @result then Search::ANSWERED_BY_AI
                  else Search::ANSWERED_BY_CACHE
                  end
    @params = listing_params(answer || fallback_answer)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

    if @text.present?
      @search = save_search(answered_by, duration_ms)
      log_generation(@result, @search) if @result
    end
    @params
  end

  # the saved search's id, once params are made (nil without a search, or when it couldn't be saved)
  def search_id = @search&.search_id

  # the one product the search names by its supplier SKU or GTIN (see identifier_match), so the listing can go straight
  # to it, without asking Claude; the search is saved as answered by Search::ANSWERED_BY_IDENTIFIER. nil when it
  # names none, so the search is turned into params instead
  def product
    return @product if defined?(@product)

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @product = identifier_match
    if @product
      @params = { search: @text, product_id: @product.product_id }
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      @search = save_search(Search::ANSWERED_BY_IDENTIFIER, duration_ms)
    end
    @product
  end

  # -----------------------------------------------------------------------------

  private

  def listing_params(answer)
    {
      search: @text,
      keywords: keyword_params(answer['keywords']),
      type: [answer['type']].compact - [ANY_TYPE],
      size: answer['sizes'],
      difficulty: answer['difficulties'],
      supplier: answer['suppliers'],
      sale: ('1' if answer['on_sale']),
      stock: [answer['stock']].compact - [ANY_STOCK],
      sort: (answer['sort'] unless answer['sort'] == ANY_SORT)
    }.merge(price_params(answer['min_price'], answer['max_price']), quilt_size_params(answer)).compact_blank
  end

  # the keywords as the listing's keywords[] params: each with its related words after ProductFilter::RELATED_SEPARATOR
  # (ex: 'ocean|nautical|beach'), tidied by ProductFilter.keyword_param (which drops one whose keyword is blank); a
  # fallback keyword (a plain word) has none
  def keyword_params(keywords)
    Array(keywords).filter_map do |keyword|
      words = keyword.is_a?(Hash) ? [keyword['word'], *Array(keyword['related'])] : [keyword]
      param = words.map { |word| word.to_s.delete(ProductFilter::RELATED_SEPARATOR) }.join(ProductFilter::RELATED_SEPARATOR)
      ProductFilter.keyword_param(param)
    end
  end

  # the one listing product whose supplier SKU or GTIN the search is, ignoring case, spaces and punctuation (ex:
  # "KT-19330", "kt 19330", "KIT2QTOB.POOLPARTY"), or a SKU's number (at least MIN_SKU_DIGITS digits in a row of it,
  # ex: "19330", "80007" for 80007QK-X), or its GTIN with or without leading zeros (ex: "0889333575597"); nil when the
  # search isn't one, or matches several (ex: a number in more than one SKU)
  def identifier_match
    query = identifier(@text)
    return if query.length < MIN_SKU_DIGITS || !query.match?(/\d/)

    # a search of digits only can also be a SKU's number, or a GTIN (compared without leading zeros)
    digits = query.sub(/\A0+/, '').presence if query.match?(/\A\d+\z/)
    matches = @filter.products.select do |product|
      sku = identifier(product.supplier_sku)
      gtin = product.gtin.to_s.gsub(/\D/, '').sub(/\A0+/, '')
      sku == query || (digits && (sku.include?(query) || gtin == digits))
    end
    matches.first if matches.one?
  end

  # a SKU / GTIN as compared: lowercase letters and digits only
  def identifier(value) = value.to_s.downcase.gsub(/[^a-z0-9]/, '')

  # saves the search, with how long it took to answer in milliseconds (the cache lookup, plus the call to Claude or the
  # keyword fallback); nil when it couldn't be saved, since failing to save doesn't fail the search
  def save_search(answered_by, duration_ms)
    Search.create!(search_type: SEARCH_TYPE, text: @text, answered_by:, params: @params, voice: @voice, duration_ms:, **@shopper)
  rescue => e
    CapturedException.log(location: 'ProductSearch#save_search', note: { text: @text }, e:)
    nil
  end

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

  # Claude's answer; the call (its tokens, cost and answer) is kept as @result, to log once the search is saved
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
    @result = result
    result[:answer]
  rescue => e
    CapturedException.log(location: 'ProductSearch', note: { text: @text }, e:)
    nil
  end

  # logs the call and its cost against the search, whether or not the answer is used; failing to log doesn't fail the
  # search. item_id is 0 when the search couldn't be saved
  def log_generation(result, search)
    ai_model = model_prompt.ai_model
    input_cost = (result[:input_tokens] / 1_000_000.0) * ai_model.input_price_per_mtok
    output_cost = (result[:output_tokens] / 1_000_000.0) * ai_model.output_price_per_mtok

    AiGeneration.create!(
      ai_model_prompt_id: model_prompt.ai_model_prompt_id,
      item_type: 'Search',
      item_id: search&.search_id || 0,
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

  # the search's price limits (swapped when the min is over the max): on the price ranges' edges (ex: under $100, over
  # $150), the ranges they cover, so they show as the price range filter; otherwise (ex: under $90, or exactly $100,
  # which no range covers) the exact limits
  def price_params(min, max)
    min = nil unless min&.positive?
    max = nil unless max&.positive?
    return {} if min.nil? && max.nil?
    min, max = max, min if min && max && min > max

    edges = ProductFilter::PRICE_RANGES.values.flat_map { |(_, low, high)| [low, high] }.compact
    return { min_price: min, max_price: max } unless [min, max].compact.all? { |price| edges.include?(price) }

    ranges = ProductFilter::PRICE_RANGES.select do |_, (_, low, high)|
      (min.nil? || (low && low >= min)) && (max.nil? || (high && high <= max))
    end
    ranges.any? ? { price: ranges.keys } : { min_price: min, max_price: max }
  end

  # the search's quilt width / length limits, in inches (ex: at least 30" wide); these win over quilt sizes, which are
  # left out when there are any
  def quilt_size_params(answer)
    limits = QUILT_SIZE_LIMITS.to_h { |key| [key.to_sym, answer[key]] }.select { |_, inches| inches&.positive? }
    limits.any? ? limits.merge(size: nil) : {}
  end

  # the search's own words as keywords, for when Claude can't answer: the ones some product in the listing has as a whole
  # word, in any form (ex: fabrics matches fabric), checked in postgres as ProductFilter matches them (see
  # products.search_vector), leaving out short and generic words, so one stray word doesn't empty the listing
  def fallback_answer
    words = @text.downcase.scan(/[[:alnum:]']+/).uniq.reject do |word|
      word.size < 3 || word.match?(/\A\d+\z/) || STOP_WORDS.include?(word) || STOP_WORDS.include?(word.delete_suffix('s'))
    end
    products = Product.where(product_id: @filter.products.map(&:product_id))
    words = words.select { |word| products.where("search_vector @@ plainto_tsquery('english', ?)", word).exists? }
    { 'keywords' => words.first(ProductFilter::MAX_KEYWORDS) }
  end

  # the answer's shape: only the listing's options can be picked
  def schema
    @schema ||= begin
      properties = {
        keywords: {
          type: 'array',
          items: {
            type: 'object',
            properties: { word: { type: 'string' }, related: { type: 'array', items: { type: 'string' } } },
            required: %w[word related],
            additionalProperties: false
          }
        },
        min_price: { anyOf: [{ type: 'number' }, { type: 'null' }] },
        max_price: { anyOf: [{ type: 'number' }, { type: 'null' }] },
        on_sale: { type: 'boolean' },
        stock: { type: 'string', enum: ProductFilter::STOCK_STATUSES.keys + [ANY_STOCK] },
        sort: { type: 'string', enum: ProductFilter::SORTS.keys + [ANY_SORT] }
      }
      properties[:type] = { type: 'string', enum: @filter.types + [ANY_TYPE] } if @filter.type_filter?
      properties[:sizes] = { type: 'array', items: { type: 'string', enum: ProductFilter::QUILT_SIZES.keys } } if @filter.quilt_sizes?
      quilt_size_limits.each { |key| properties[key.to_sym] = { anyOf: [{ type: 'number' }, { type: 'null' }] } }
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
      quilt_size_limits_note,
      (option_list('Difficulty (pick every level that fits)', @filter.difficulties.map { |value| [value, @filter.difficulty_label(value)] }) if @filter.difficulty_filter?),
      (option_list('Supplier (pick every one the shopper names)', @filter.suppliers.map { |supplier| [supplier.token, supplier.handle] }) if @filter.suppliers.any?),
      option_list("Stock (pick one, or \"#{ANY_STOCK}\")", ProductFilter::STOCK_STATUSES.to_a),
      option_list("Sort (pick one only when the shopper asks for an order, such as \"highest price first\", \"most expensive\", \"cheapest first\" or \"alphabetical\"; otherwise \"#{ANY_SORT}\")", ProductFilter::SORTS.to_a),
      ON_SALE_NOTE,
      KEYWORDS_NOTE
    ].compact.join("\n")
  end

  def option_list(heading, options)
    "#{heading}:\n#{options.map { |value, label| "- #{value}: #{label}" }.join("\n")}\n"
  end

  # the quilt width / length limits the listing offers: width with the quilt size filter, and length when it has one
  def quilt_size_limits
    return [] unless @filter.quilt_sizes?
    @filter.quilt_lengths? ? QUILT_SIZE_LIMITS : QUILT_SIZE_LIMITS.grep(/width/)
  end

  # how to read the shopper's measurements into the quilt width / length limits (nil without them)
  def quilt_size_limits_note
    return if quilt_size_limits.empty?
    dimensions = @filter.quilt_lengths? ? 'width and length' : 'width'
    <<~NOTE
      Quilt #{dimensions}, in inches (#{quilt_size_limits.join(', ')}; the width is the shorter side):
      - Use these only when the shopper gives a measurement in inches (or feet, times 12); a named size (king, throw, baby) is a quilt size above. With a measurement, leave sizes empty and set the type to quilt.
      - "at least 30 inches wide" or "30\" wide or more" is min_width 30; "no wider than 60 inches" is max_width 60; "between 50 and 70 inches wide" is min_width 50 and max_width 70.
      - A measurement without a side (ex: "at least 60 inches") is the width. "60 x 80" or "60 by 80" is about width 60 and length 80: min / max 5 inches either side (min_width 55, max_width 65, min_length 75, max_length 85).
      - With no measurement mentioned, these are all null.
    NOTE
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
