module HawthorneCore::PageSectionsHelper

  # -----------------------------------------------------------------------------

  # partial names that may be rendered for a page section, one per block type.
  # a section renders the partial whose name matches its block type's handle,
  # parameterized to snake_case (e.g. 'Hero Image' => 'hero_image').
  #
  # rendering keys on the handle, not page_block_type_id: block types live in the
  # shared admin database and their ids are identity-generated, so the same block
  # type has different ids in each environment (dev vs prod). the handle is the
  # stable, unique business key and is identical everywhere.
  #
  # partials live in app/views/page_sections/ and each receives the section as a
  # `section` local. adding a new block type = create the matching partial and
  # add its name here. a handle with no matching partial renders nothing, so new
  # block types can exist in the admin before their markup does. a site that
  # needs to differ can override individual partials (host views win lookup) or
  # pass its own whitelist via `partials:`.
  BLOCK_PARTIALS = %w[
    hero_image
    header
    body
    image_with_text
    footer_sign_up_link
    featured_fabrics
    1_image
    2_images
    3_images
    4_images
    sale_banners
  ].freeze

  # -----------------------------------------------------------------------------

  # render a page section using the partial matching its block type's handle. the
  # handle is resolved from page_block_type_id (see page_block_type_handles) and
  # parameterized to a partial name; a name not in `partials` renders nothing.
  def render_page_section(section, partials: BLOCK_PARTIALS)
    handle = page_block_type_handles[section.page_block_type_id]
    return if handle.nil?
    name = handle.parameterize(separator: '_')
    return unless partials.include?(name)
    render("page_sections/#{name}", section: section)
  end

  # -----------------------------------------------------------------------------

  # page_block_type_id => handle for every block type, looked up once per request.
  # block types are few and rarely change, so a single query is cheap and keeps
  # rendering decoupled from the per-environment numeric ids.
  def page_block_type_handles
    @page_block_type_handles ||= PageBlockType.pluck(:page_block_type_id, :handle).to_h
  end

  # -----------------------------------------------------------------------------

  # responsive widths (css pixels) requested from cloudflare. the browser picks
  # the smallest that covers its layout width times its device pixel ratio, so
  # phones fetch small images and retina desktops fetch large ones.
  IMAGE_WIDTHS = [640, 960, 1280, 1920].freeze

  # -----------------------------------------------------------------------------

  # render an <img> (see ImageComponent) for an image referenced by id in the
  # section's content_attrs, served through cloudflare's transformation cdn
  # (compressed + resized per device) via a responsive srcset. renders nothing
  # when the id is absent, the image is missing, or it has no stored file, so a
  # section can exist before its image is set.
  def page_section_image_tag(section, key: 'image_id', sizes: '100vw')
    image_id = section.content_attrs[key]
    return if image_id.blank?
    image = Image.find_by(image_id: image_id)
    return if image&.file_key.blank?
    render(ImageComponent.new(image: image, widths: IMAGE_WIDTHS, sizes: sizes, loading: nil))
  end

  # -----------------------------------------------------------------------------

  # render the section's image (see page_section_image_tag) wrapped in a link
  # when content_attrs carries a link_url, otherwise the bare image. renders
  # nothing when the section has no image.
  def page_section_linked_image(section, link_key: 'link_url', image_key: 'image_id', sizes: '100vw')
    image = page_section_image_tag(section, key: image_key, sizes: sizes)
    return if image.blank?
    url = section.content_attrs[link_key]
    return image if url.blank?
    link_to(image, url)
  end

  # -----------------------------------------------------------------------------

end
