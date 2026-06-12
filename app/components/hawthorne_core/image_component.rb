class HawthorneCore::ImageComponent < ViewComponent::Base

  include HawthorneCore::ImageHelper

  def initialize(image:)
    @image = image
  end

  # the image preset (via image type) carries the responsive widths and sizes
  def preset
    @image.image_type&.image_preset
  end

  def widths
    preset&.widths || []
  end

  # a cloudflare-transformed candidate per preset width: "url 2000w, url 1200w"
  def srcset
    return if widths.empty?
    widths.map { |width| "#{media_url_for_key(@image.file_key, version: @image.updated_at.to_i, width: width)} #{width}w" }.join(', ')
  end

  # the preset's sizes attribute, telling the browser which candidate to pick.
  # when the preset has none, fall back to the largest generated width so the
  # browser renders the image at its intended size rather than defaulting to
  # 100vw (which, with no css width, stretches it to the full viewport)
  def sizes
    return preset.sizes if preset&.sizes.present?
    return if widths.empty?
    "#{widths.max}px"
  end

  # default src: the largest preset width, or the untransformed original
  def src
    return media_url_for_key(@image.file_key, version: @image.updated_at.to_i) if widths.empty?
    media_url_for_key(@image.file_key, version: @image.updated_at.to_i, width: widths.max)
  end

  def dimensions
    return '—' unless @image.width && @image.height
    "#{@image.width}×#{@image.height}"
  end

end
