class ImageComponent < ViewComponent::Base

  include HawthorneCore::ImageHelper

  # renders an Image as an <img> served from cloudflare, resized so the browser never downloads the full-size original
  #
  # image: the Image to render; when nil (or it has no stored file) the empty fallback renders instead
  # width: a single width (css pixels) to request, for fixed-size previews; shorthand for widths: [width]
  # widths: the responsive widths to offer in the srcset; defaults to the image type's preset
  # sizes: the <img> sizes attribute; defaults to the preset's sizes, otherwise the largest width
  # alt: defaults to the image's alt text
  # empty: what to render when there is no image (nothing by default)
  # html_options: any other <img> attributes (class:, style:, title:, data:, ...)
  def initialize(image:, width: nil, widths: nil, sizes: nil, alt: nil, loading: 'lazy', empty: nil, **html_options)
    @image = image
    @widths = width ? [width] : widths
    @sizes = sizes
    @alt = alt
    @loading = loading
    @empty = empty
    @html_options = html_options
  end

  def render?
    image? || @empty.present?
  end

  def image?
    @image&.file_key.present?
  end

  # the <img> attributes, leaving out any that are blank
  def image_options
    { srcset:, sizes:, alt:, loading: @loading, **@html_options }.compact_blank
  end

  # -----------------------------------------------------------------------------

  private

  # the image preset (via the image type), consulted only when no widths are given so callers that pass their own
  # widths never load it
  def preset
    return if @widths
    @image.image_type&.image_preset
  end

  def widths
    @widths || preset&.widths || []
  end

  # a cloudflare-transformed candidate per width: "url 640w, url 1280w" (none for a single width)
  def srcset
    return if widths.size < 2
    widths.map { |w| "#{url(w)} #{w}w" }.join(', ')
  end

  # the explicit sizes, otherwise the preset's. when neither is set, fall back to the largest width so the browser
  # renders the image at its intended size rather than defaulting to 100vw (which stretches it to the full viewport)
  def sizes
    return if srcset.nil?
    @sizes || preset&.sizes.presence || "#{widths.max}px"
  end

  def alt
    @alt.presence || @image.alt_text.presence
  end

  # default src: the largest width, or the untransformed original when there are no widths
  def src
    url(widths.max)
  end

  def url(width)
    media_url_for_key(@image.file_key, width:, version: @image.file_version)
  end

end
