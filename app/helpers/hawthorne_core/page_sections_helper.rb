module HawthorneCore::PageSectionsHelper

  # -----------------------------------------------------------------------------

  # default map of page_block_type_id => partial name, shared by every site.
  # the id is immutable (block types live in the shared admin database), so
  # renaming a block type's handle in the admin never affects rendering.
  # partials live in app/views/page_sections/ and each receives the section as a
  # `section` local. adding a new block type = add one line here and create the
  # matching partial. a site that needs to differ can override individual
  # partials (host views win lookup) or pass its own map via `partials:`.
  BLOCK_PARTIALS = {
    3 => 'hero_image',
    5 => 'header',
    6 => 'body',
    7 => 'footer_sign_up_link',
    8 => 'featured_fabrics',
  }.freeze

  # -----------------------------------------------------------------------------

  # render a page section using the partial mapped to its block type id. a block
  # type with no mapping renders nothing, so new types can be created in the
  # admin before their markup exists.
  def render_page_section(section, partials: BLOCK_PARTIALS)
    name = partials[section.page_block_type_id]
    return if name.nil?
    render("page_sections/#{name}", section: section)
  end

  # -----------------------------------------------------------------------------

  # responsive widths (css pixels) requested from cloudflare. the browser picks
  # the smallest that covers its layout width times its device pixel ratio, so
  # phones fetch small images and retina desktops fetch large ones.
  IMAGE_WIDTHS = [640, 960, 1280, 1920].freeze

  # build a host-relative cloudflare image-transformation url for a source image
  # url. host-relative (no scheme/host) so each site transforms through its own
  # cloudflare zone. format=auto serves avif/webp when the browser supports it,
  # otherwise the original format. see https://developers.cloudflare.com/images/
  def cdn_image_url(src, width)
    "/cdn-cgi/image/format=auto,quality=85,width=#{width}/#{src}"
  end

  # -----------------------------------------------------------------------------

  # render an <img> for an image referenced by id in the section's content_attrs.
  # looks up the HawthorneCore::Image and renders its attached active storage
  # file. renders nothing when the id is absent, the image is missing, or it has
  # no attached file, so a section can exist before its image is set.
  #
  # in deployed environments the image is served through cloudflare's
  # transformation cdn (compressed + resized per device) via a responsive
  # srcset. locally there is no cloudflare in front of the app, so it falls back
  # to the plain active storage url and nothing breaks in development.
  def page_section_image_tag(section, key: 'image_id', sizes: '100vw')
    image_id = section.content_attrs[key]
    return if image_id.blank?
    image = HawthorneCore::Image.find_by(image_id: image_id)
    return if image.nil? || !image.file.attached?
    return image_tag(image.file) if Rails.env.development? || Rails.env.test?
    src = image.file.url
    srcset = IMAGE_WIDTHS.map { |w| "#{cdn_image_url(src, w)} #{w}w" }.join(', ')
    image_tag(cdn_image_url(src, IMAGE_WIDTHS.last), srcset: srcset, sizes: sizes)
  end

  # -----------------------------------------------------------------------------

  # render the section's image (see page_section_image_tag) wrapped in a link
  # when content_attrs carries a link_url, otherwise the bare image. renders
  # nothing when the section has no image.
  def page_section_linked_image(section, link_key: 'link_url', image_key: 'image_id')
    image = page_section_image_tag(section, key: image_key)
    return if image.blank?
    url = section.content_attrs[link_key]
    return image if url.blank?
    link_to(image, url)
  end

  # -----------------------------------------------------------------------------

end
