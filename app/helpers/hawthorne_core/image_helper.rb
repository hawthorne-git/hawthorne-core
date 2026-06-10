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
    puts 'here in attach_image_helper-1'
    return unless file.present?
    puts 'here in attach_image_helper-2'
    extension = File.extname(file.original_filename)
    image.file.attach(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type,
      key: "images/#{dir}/#{SecureRandom.uuid}#{extension}"
    )
  end

end