require 'net/http'
require 'json'

# Voyage AI service: embeddings, lists of numbers standing for what a text means (see ProductEmbedding)
class Services::VoyageSvc

  URL = URI('https://api.voyageai.com/v1/embeddings')

  # seconds to connect / wait for the embeddings
  TIMEOUT = 30

  # the most texts embedded in one request
  MAX_TEXTS = 100

  # Embeds texts with the model: input_type 'document' for what's searched (ex: a product), 'query' for what's
  # searched for (ex: a shopper's search), so the two are made to match each other.
  #
  # Returns { embeddings: [Array<Float>, ...] in the texts' order, total_tokens: Integer }
  #
  # Raises when the request fails or times out
  def embed(texts:, model_api:, input_type:, timeout: TIMEOUT)
    request = Net::HTTP::Post.new(URL, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{ENV.fetch('VOYAGE_KEY')}")
    request.body = { input: texts, model: model_api, input_type: }.to_json
    response = Net::HTTP.start(URL.host, URL.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
      http.request(request)
    end
    raise "Voyage embeddings failed (#{response.code}): #{response.body.to_s.first(300)}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    {
      embeddings: body.fetch('data').sort_by { |row| row['index'] }.map { |row| row.fetch('embedding') },
      total_tokens: body.dig('usage', 'total_tokens').to_i
    }
  end

end
