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
