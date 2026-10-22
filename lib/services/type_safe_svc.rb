require 'net/http'
require 'base64'
require 'json'
require 'securerandom'
require 'vips'

# TypeSafe service (its Jev model)
class Services::TypeSafeSvc

  URL = 'https://api.typesafe.ai/v1/systemone'

  MODEL = 'jev-preview'

  # Jev rejects large images ("Invalid image dimensions"; product images are 4096x4096), so every image is sent as a
  # jpg shrunk to this long edge
  MAX_EDGE = 1024

  # Sends an image (its bytes) to Jev with one choice question, plus any context (ex: the product name), and returns
  # the answer: { 'choice' => one of the criteria keys, 'confidence' => 0..1, 'probabilities' => { key => 0..1 } }.
  # criteria maps each choice to what it means (ex: { 'quilt' => 'a quilt' })
  def image_choice(image_bytes:, instructions:, criteria:, context: nil)
    key = SecureRandom.uuid
    jpg = Vips::Image.thumbnail_buffer(image_bytes, MAX_EDGE, size: :down).write_to_buffer('.jpg', Q: 85)

    body = {
      model: MODEL,
      state: context ? "#{context}\n#{key}" : key,
      assets: {
        key => { type: 'image', format: 'jpg', data_base64: Base64.strict_encode64(jpg) }
      },
      questions: {
        answer: { type: 'choice', instructions:, criteria: }
      }
    }

    response = Net::HTTP.post(
      URI(URL),
      body.to_json,
      'Authorization' => "Bearer #{HawthorneCore::AppConfig.typesafe_api_key}",
      'Content-Type' => 'application/json',
      'TypeSafe-Danger-Zone-Images' => 'true'
    )
    raise "TypeSafe HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).dig('answers', 'answer') || raise("TypeSafe response has no answer: #{response.body}")
  end

end
