module HawthorneCore::ImageHelper

  def media_url(attachment, width: nil, quality: 85)
    media_url_for_key(attachment.blob.key, width: width, quality: quality)
  end

  # build the same cloudflare media url straight from a stored blob key, avoiding
  # an active storage blob query (images keep the key in their file_key column)
  def media_url_for_key(key, width: nil, quality: 85)
    host = HawthorneCore::AppConfig.media_host
    if width
      "#{host}/cdn-cgi/image/width=#{width},quality=#{quality},format=auto/#{key}"
    else
      "#{host}/#{key}"
    end
  end

  def attach_image_helper(image:, file:)
    return unless file.present?
    extension = File.extname(file.original_filename)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      key: "images/#{image.image_type.slug}/#{image.token}#{extension}"
    )
    image.file.attach(blob)
    width, height = image_dimensions(file)
    image.update!(
      active_storage_blob_id: blob.id,
      file_key: blob.key,
      content_type: blob.content_type,
      byte_size: blob.byte_size,
      width: width,
      height: height
    )
  end

  private

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