require 'net/http'
require 'base64'
require 'json'
require 'vips'

# Claude service
class Services::CaludeSvc

  ALT_TEXT_SCHEMA = {
    type: 'object',
    properties: {
      alt_text: { type: 'string' }
    },
    required: %w[alt_text],
    additionalProperties: false
  }.freeze

  # Fetches the image at image_url, converts it to JPEG, sends it to Claude
  # with the given prompt, and returns the generated alt text plus token usage.
  #
  # Returns { alt_text: String, input_tokens: Integer, output_tokens: Integer }
  def image_alt_text(image_url:, model_api:, max_tokens:, prompt:)
    jpeg_bytes = fetch_as_jpeg(image_url)

    msg = client.messages.create(
      model: model_api,
      max_tokens: max_tokens,
      output_config: { format: { type: 'json_schema', schema: ALT_TEXT_SCHEMA } },
      messages: [
        { role: 'user', content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: Base64.strict_encode64(jpeg_bytes) } },
          { type: 'text', text: prompt }
        ] }
      ]
    )

    alt_text = JSON.parse(msg.content.find { |b| b.type == :text }.text).fetch('alt_text').to_s.strip

    {
      alt_text: alt_text,
      input_tokens: msg.usage.input_tokens,
      output_tokens: msg.usage.output_tokens
    }
  end

  # Fetches the image at image_url, converts it to JPEG, and sends it to Claude with instructions (the system prompt)
  # and a JSON schema its answer must match.
  #
  # Returns { answer: Hash matching the schema, model: String, input_tokens: Integer, output_tokens: Integer }
  #
  # Raises when the request fails, or Claude declines or runs out of tokens
  def image_json_answer(image_url:, model_api:, max_tokens:, instructions:, schema:)
    jpeg_bytes = fetch_as_jpeg(image_url)

    msg = client.messages.create(
      model: model_api,
      max_tokens: max_tokens,
      system_: instructions,
      output_config: { format: { type: 'json_schema', schema: schema } },
      messages: [
        { role: 'user', content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: Base64.strict_encode64(jpeg_bytes) } }
        ] }
      ]
    )

    raise "Claude declined (#{msg.stop_details&.category}): #{msg.stop_details&.explanation}" if msg.stop_reason == :refusal
    raise "Claude ran out of tokens (max_tokens: #{max_tokens})" if msg.stop_reason == :max_tokens

    text_block = msg.content.find { |b| b.type == :text } || raise('Claude response has no text')

    {
      answer: JSON.parse(text_block.text),
      model: msg.model.to_s,
      input_tokens: msg.usage.input_tokens,
      output_tokens: msg.usage.output_tokens
    }
  end

  # Sends text to Claude with instructions (the system prompt) and a JSON schema its answer must match, thinking at the
  # given effort (ex: :low). If Claude declines for policy reasons, the server retries on the model's default
  # fallback. timeout: seconds to wait, without retrying (nil for the client's default, with retries).
  #
  # Returns { answer: Hash matching the schema, model: String, input_tokens: Integer, output_tokens: Integer }
  #
  # Raises when the request fails or times out, or Claude declines or runs out of tokens
  def json_answer(model_api:, effort:, max_tokens:, instructions:, text:, schema:, timeout: nil)
    msg = client.beta.messages.create(
      model: model_api,
      max_tokens: max_tokens,
      system_: instructions,
      output_config: { effort: effort, format: { type: 'json_schema', schema: schema } },
      fallbacks: :default,
      betas: ['server-side-fallback-2026-07-01'],
      messages: [{ role: 'user', content: text }],
      request_options: timeout ? { timeout: timeout, max_retries: 0 } : {}
    )

    raise "Claude declined (#{msg.stop_details&.category}): #{msg.stop_details&.explanation}" if msg.stop_reason == :refusal
    raise "Claude ran out of tokens (max_tokens: #{max_tokens})" if msg.stop_reason == :max_tokens

    text_block = msg.content.find { |b| b.type == :text } || raise('Claude response has no text')

    {
      answer: JSON.parse(text_block.text),
      model: msg.model.to_s,
      input_tokens: msg.usage.input_tokens,
      output_tokens: msg.usage.output_tokens
    }
  end

  # -------------------------------------------------------------------------

  private

  def client
    @client ||= Anthropic::Client.new(api_key: ENV.fetch('CLAUDE_KEY'))
  end

  def fetch_as_jpeg(url)
    raw = Net::HTTP.get(URI(url))
    Vips::Image.new_from_buffer(raw, '').write_to_buffer('.jpg', Q: 85)
  end

end
