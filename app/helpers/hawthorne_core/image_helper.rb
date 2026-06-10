module HawthorneCore::ImageHelper
  def media_url(attachment, width: nil, quality: 85)
    key = attachment.blob.key
    host = HawthorneCore::AppConfig.media_host
    if width
      "#{host}/cdn-cgi/image/width=#{width},quality=#{quality},format=auto/#{key}"
    else
      "#{host}/#{key}"
    end
  end

  def attach_image_helper(image:, file:, dir:)
    return unless file.present?
    extension = File.extname(file.original_filename)
    # upload synchronously rather than relying on active storage's deferred
    # after_commit upload, which silently no-ops under this app's split
    # connection-pool setup (ActiveStorage::Record and the models are separate
    # pools on the app db, so the attachment's touch: true reloads the record
    # and the upload callback fires on an instance with no pending changes)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      key: "images/#{dir}/#{SecureRandom.uuid}#{extension}"
    )
    image.file.attach(blob)
  end

end