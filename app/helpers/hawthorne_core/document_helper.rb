module HawthorneCore::DocumentHelper

  # the largest file downloaded from a link (see attach_document_helper's url:)
  DOWNLOAD_MAX_BYTES = 50.megabytes

  # how many redirects a link may follow (ex: http -> https, or a maker's download page -> its file)
  DOWNLOAD_MAX_REDIRECTS = 3

  # the document's file url on the media host; versioned so a replaced file isn't served from a cache
  def document_url(document)
    "#{HawthorneCore::AppConfig.media_host}/#{document.file_key}?v=#{document.file_version}"
  end

  # store a document's file, from an upload (file:) or downloaded from a web link (url:; ex: a maker's color card
  # pdf). the file must be one of its document type's file types (judged from its contents, not just its name). its
  # key is documents/<type slug>/<token>.<ext>, so replacing the file reuses the key. raises when it can't be stored
  def attach_document_helper(document:, file: nil, url: nil)
    upload = file.present? ? { io: file, filename: file.original_filename, content_type: file.content_type } : download_document(url)
    content_type = Marcel::MimeType.for(upload[:io], name: upload[:filename], declared_type: upload[:content_type])
    upload[:io].rewind
    document_type = document.document_type
    unless document_type.content_types.to_a.include?(content_type)
      raise ArgumentError, "#{upload[:filename]} is #{DocumentType::CONTENT_TYPES[content_type] || content_type}, " \
                           "but #{document_type.handle} only accepts #{document_type.content_type_names}"
    end

    replacing = document.file.attached?
    # purge the current blob first to free the key (and delete the old R2 object) before uploading the replacement
    document.file.purge if replacing
    blob = ActiveStorage::Blob.create_and_upload!(
      io: upload[:io],
      filename: upload[:filename],
      content_type:,
      identify: false,
      key: "documents/#{document_type.slug}/#{document.token}#{DocumentType::EXTENSIONS[content_type]}"
    )
    document.file.attach(blob)
    attributes = {
      active_storage_blob_id: blob.id,
      file_key: blob.key,
      content_type: blob.content_type,
      byte_size: blob.byte_size
    }
    # bump the cache-busting version only when replacing an existing file
    attributes[:file_version] = document.file_version.to_i + 1 if replacing
    document.update!(**attributes)
  end

  private

  # download a web link's file, following a few redirects; returns it like an upload ({ io:, filename:, content_type: })
  def download_document(url, redirects_left: DOWNLOAD_MAX_REDIRECTS)
    uri = URI.parse(url.to_s.strip)
    raise ArgumentError, 'The link must be a web link (http:// or https://)' unless uri.is_a?(URI::HTTP) && uri.host.present?

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 60) do |http|
      http.request(Net::HTTP::Get.new(uri)) do |response|
        case response
        when Net::HTTPRedirection
          raise ArgumentError, 'The link redirects too many times' if redirects_left.zero?

          return download_document(URI.join(uri, response['location']).to_s, redirects_left: redirects_left - 1)
        when Net::HTTPSuccess
          body = String.new(encoding: Encoding::BINARY)
          response.read_body do |chunk|
            body << chunk
            raise ArgumentError, "The file is over #{DOWNLOAD_MAX_BYTES / 1.megabyte} MB" if body.bytesize > DOWNLOAD_MAX_BYTES
          end
          filename = URI.decode_www_form_component(File.basename(uri.path)).presence || 'document'
          return { io: StringIO.new(body), filename:, content_type: response.content_type }
        else
          raise ArgumentError, "The link couldn't be downloaded (#{response.code} #{response.message})"
        end
      end
    end
  rescue URI::InvalidURIError
    raise ArgumentError, 'The link must be a web link (http:// or https://)'
  end

end
