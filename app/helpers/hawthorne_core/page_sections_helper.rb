module HawthorneCore::PageSectionsHelper

  # -----------------------------------------------------------------------------

  # render a page section using a caller-supplied map of page_block_type_id =>
  # partial name. the id is immutable, so renaming a block type's handle in the
  # admin never affects rendering. each site owns its own map and provides the
  # matching partials under app/views/page_sections/, where each receives the
  # section as a `section` local. a block type with no mapping renders nothing,
  # so new types can be created in the admin before their markup exists on a
  # given site.
  def render_page_section(section, partials:)
    name = partials[section.page_block_type_id]
    return if name.nil?
    render("page_sections/#{name}", section: section)
  end

  # -----------------------------------------------------------------------------

end
