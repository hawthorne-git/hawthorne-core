require 'net/http'
require 'base64'
require 'json'
require 'securerandom'
require 'vips'

# TypeSafe service (its Jev model)
class Services::TypeSafeSvc

  URL = 'https://api.typesafe.ai/v1/systemone'

  # seconds to connect / wait for an answer (Jev usually answers in under a second)
  TIMEOUT = 20

  # a failure worth trying again later: the request timed out or couldn't connect, TypeSafe was rate limiting (429), or
  # it had a server error (5xx)
  class TransientError < StandardError; end

  NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET,
                    Errno::EHOSTUNREACH, SocketError, OpenSSL::SSL::SSLError, EOFError].freeze

  # Jev rejects large images ("Invalid image dimensions"; product images are 4096x4096), so every image is sent as a
  # jpg shrunk to this long edge
  MAX_EDGE = 1024

  # Sends an image (its bytes) to a Jev model (ex: jev-preview) with one choice question, plus any context (ex: the
  # product name). criteria maps each choice to what it means (ex: { 'quilt' => 'a quilt' }).
  #
  # Returns { answer: { 'choice' => one of the criteria keys, 'confidence' => 0..1, 'probabilities' => { key => 0..1 } },
  #           model: the model that answered (ex: jev-1.14.0), input_tokens: Integer, output_tokens: Integer }
  #
  # Raises TransientError when it's worth trying again later, else RuntimeError
  def image_choice(model_api:, image_bytes:, instructions:, criteria:, context: nil)
    key = SecureRandom.uuid
    jpg = Vips::Image.thumbnail_buffer(image_bytes, MAX_EDGE, size: :down).write_to_buffer('.jpg', Q: 85)

    body = {
      model: model_api,
      state: context ? "#{context}\n#{key}" : key,
      assets: {
        key => { type: 'image', format: 'jpg', data_base64: Base64.strict_encode64(jpg) }
      },
      questions: {
        answer: { type: 'choice', instructions:, criteria: }
      }
    }

    response = post(body)
    if response.code == '429' || response.is_a?(Net::HTTPServerError)
      raise TransientError, "TypeSafe HTTP #{response.code}: #{response.body}"
    end
    raise "TypeSafe HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    result = JSON.parse(response.body)
    answer = result.dig('answers', 'answer') || raise("TypeSafe response has no answer: #{response.body}")

    {
      answer: answer,
      model: result['model'],
      input_tokens: result.dig('usage', 'input_tokens').to_i,
      output_tokens: result.dig('usage', 'output_tokens').to_i
    }
  end

  # -------------------------------------------------------------------------

  private

  def post(body)
    uri = URI(URL)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT) do |http|
      http.post(uri.path, body.to_json,
                'Authorization' => "Bearer #{HawthorneCore::AppConfig.typesafe_api_key}",
                'Content-Type' => 'application/json',
                'TypeSafe-Danger-Zone-Images' => 'true')
    end
  rescue *NETWORK_ERRORS => e
    raise TransientError, "TypeSafe #{e.class}: #{e.message}"
  end

end
