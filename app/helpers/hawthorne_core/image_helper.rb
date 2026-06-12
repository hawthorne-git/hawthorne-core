module HawthorneCore::ImageHelper

  # cloudflare's transform pipeline only decodes certain source formats on every
  # plan (avif and heic require enterprise). anything not in this list is
  # transcoded to webp on upload so the stored master is always resizable.
  CLOUDFLARE_TRANSFORMABLE_TYPES = %w[image/jpeg image/png image/gif image/webp image/svg+xml].freeze

  def media_url(attachment, width: nil, quality: 85)
    media_url_for_key(attachment.blob.key, width: width, quality: quality, version: attachment.record.file_version)
  end

  # build the same cloudflare media url straight from a stored blob key, avoiding
  # an active storage blob query (images keep the key in their file_key column)
  def media_url_for_key(key, width: nil, quality: 85, version: nil)
    host = HawthorneCore::AppConfig.media_host
    url = if width
      "#{host}/cdn-cgi/image/width=#{width},quality=#{quality},format=auto/#{key}"
    else
      "#{host}/#{key}"
    end
    # the key is stable across replacements, so version the url (when a token is
    # given) to bust cloudflare/browser caches when the image is replaced.
    version ? "#{url}?v=#{version}" : url
  end

  def attach_image_helper(image:, file:)
    return unless file.present?
    upload = normalize_upload(file)
    replacing = image.file.attached?
    # the key is derived from the image's stable token, so replacing the image
    # reuses the same key. purge the current blob first to free the unique key
    # (and delete the old R2 object) before uploading the replacement.
    image.file.purge if replacing
    blob = ActiveStorage::Blob.create_and_upload!(
      io: upload[:io],
      filename: upload[:filename],
      content_type: upload[:content_type],
      key: "images/#{image.image_type.slug}/#{image.token}#{upload[:extension]}"
    )
    image.file.attach(blob)
    width, height = image_dimensions(file)
    attributes = {
      active_storage_blob_id: blob.id,
      file_key: blob.key,
      content_type: blob.content_type,
      byte_size: blob.byte_size,
      width: width,
      height: height
    }
    # bump the cache-busting version only when replacing an existing file; a new
    # image keeps the column default for its first upload.
    attributes[:file_version] = image.file_version.to_i + 1 if replacing
    image.update!(**attributes)
  end

  private

  # keep cloudflare-resizable uploads as-is; transcode everything else (avif,
  # heic, or anything mislabeled) to a webp master so the transform pipeline
  # works on every plan. dimensions are unchanged, so width/height are still
  # read from the original upload below.
  def normalize_upload(file)
    if CLOUDFLARE_TRANSFORMABLE_TYPES.include?(file.content_type)
      {
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        extension: File.extname(file.original_filename)
      }
    else
      webp = Vips::Image.new_from_file(file.path).webpsave_buffer(Q: 90)
      {
        io: StringIO.new(webp),
        filename: "#{File.basename(file.original_filename, '.*')}.webp",
        content_type: 'image/webp',
        extension: '.webp'
      }
    end
  end

  # active storage's image analyzer only fills in blob metadata width/height when
  # config.active_storage.variant_processor is :vips or :mini_magick; this app sets
  # it to :disabled (cloudflare handles transforms), so the analyzer never runs.
  # read the dimensions straight from the uploaded file with libvips instead.
  def image_dimensions(file)
    vips_image = Vips::Image.new_from_file(file.path)
    [vips_image.width, vips_image.height]
  rescue StandardError
    [nil, nil]
  end

end