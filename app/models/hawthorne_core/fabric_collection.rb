class HawthorneCore::FabricCollection < Administration::Repository::Fabric::FabricCollection

  include HawthorneCore::FabricCollection::PreviewImage,
          HawthorneCore::FabricCollection::Supplier

  # -----------------------------------------------------------------------------

  self.table_name = 'fabric_collections'

  # -----------------------------------------------------------------------------

  has_many :fabric_collection_themes, class_name: 'Core::FabricCollectionTheme'

  has_one_attached :poster_image_2025

  has_one_attached :precut_image_2025

  # -----------------------------------------------------------------------------

  def id = fabric_collection_id

  # -----------------------------------------------------------------------------

  # build the fabric collection show page html title
  # ex: Berry Market Fabric Collection | Beverly McCullough
  def html_title_show(designer)
    handle + ' Fabric Collection | ' + designer.handle
  end

  # build the fabric collection show page meta description
  # ex: Berry Market fabric collection is designed by Beverly McCullough for Riley Blake Designs
  def meta_description_show(designer, supplier_name)
    _meta_description = handle + ' fabric collection is designed by ' + designer.handle + ' for ' + supplier_name + '.'
    _meta_description += ' ' + meta_description if meta_description.present?
    _meta_description
  end

  # build the fabric collection show page breadcrumbs
  # ex: Fabric Collections > Hester and Cook > Sweet Spring
  def breadcrumbs_show(designer)
    [
      { title: 'Fabric Collections', link: fabric_collections_path },
      { title: designer.handle, link: designer_link(designer) },
      { title: handle, link: nil }
    ]
  end

  # create a raw a-href link for the fabric collection
  def raw_a_href_link
    '<a href="' + fabric_collection_link(self) + '">' + handle + '</a>'
  end

  # -----------------------------------------------------------------------------

  # find the fabric collection color stories (sections)
  def color_stories
    return nil unless show_fabric_products_by_color_story?
    Core::FabricCollectionSection.
      select(Core::FabricCollectionSection.fabric_collection_select_columns).
      where(fabric_collection_id: fabric_collection_id).
      where(is_deleted: false).
      order(order_nbr: :asc).
      load
  end

  # find the designer for the fabric collection
  def designer
    Core::Designer.
      select(Core::Designer.fabric_collection_select_columns).
      find_by(designer_id: designer_id, is_deleted: false)
  end

  # find the fabric products for the fabric collection
  def fabric_products
    Core::FabricProduct.
      includes(:product).
      joins(:product).
      select(Core::FabricProduct.fabric_collection_select_columns).
      where(fabric_collection_id: fabric_collection_id).
      where(products: { is_deleted: false }).
      order(order_nbr: :asc).
      load
  end

  # find the fabric precut products for the fabric collection
  def fabric_precut_products
    Core::FabricPrecutProduct.
      includes(:product).
      joins(:fabric_precut_type, :product).
      select(Core::FabricPrecutProduct.fabric_collection_select_columns).
      where(fabric_collection_id: fabric_collection_id).
      where(products: { is_deleted: false }).
      order(fabric_precut_types: { order_nbr: :asc }).
      order(products: { handle: :asc }).
      load
  end

  # find fabric panels from the same collection
  def fabric_product_panels
    Core::FabricProduct.
      joins(:product).
      where(fabric_collection_id: fabric_collection_id).
      where('LOWER(products.handle) LIKE ?', '%panel%').
      where(products: { is_deleted: false }).
      order(products: { handle: :asc }).
      load
  end

  # find fabric widebacks from the same collection
  def fabric_product_widebacks
    Core::FabricProduct.
      joins(:product).
      where(fabric_collection_id: fabric_collection_id).
      where('LOWER(products.handle) LIKE ?', '%wideback%').
      where(products: { is_deleted: false }).
      order(products: { handle: :asc }).
      load
  end

  # -----------------------------------------------------------------------------

  #  get the poster image - the image shown when viewing the fabric collection
  def poster_image
    poster_image_2025
  end

  # determine if a poster image exists
  def poster_image?
    !poster_image.attachment.nil?
  end

  # -------------------

  #  get the precut image - the image shown when the fabric collections precut image does not exist
  def precut_image
    precut_image_2025
  end

  # determine if a precut image exists
  def precut_image?
    !precut_image.attachment.nil?
  end

  # -----------------------------------------------------------------------------

  # determine if an abbreviated description exists
  def abbreviated_description?
    abbreviated_description.present?
  end

  # determine if a background color has been set for the fabric collection
  def background_color?
    background_color.present?
  end

  # determine if the fabric collection is coming soon (not released)
  def coming_soon?
    !released?
  end

  # determine if there exists a description for viewing a fabric collection
  def fabric_collection_description?
    full_description?
  end

  # determine if a full (poster) description exists
  def full_description?
    poster_description.present?
  end

  # determine if the fabric collection is inactive
  def inactive?
    is_deleted
  end

  # determine if there exists a description for viewing a product in the fabric collection
  def product_description?
    abbreviated_description? || full_description?
  end

  # determine if the fabric collection is released
  def released?
    is_released
  end

  # determine if the fabric collection should show its fabric products by color story
  # this turns to false for a fabric collection that has color stories, when a percentage of the fabric products are no longer available
  def show_fabric_products_by_color_story?
    show_fabric_products_by_color_story
  end

  # -----------------------------------------------------------------------------

  def full_description
    poster_description
  end

  # -----------------------------------------------------------------------------

  def description_with_links(description_text, sub_fabric_collection_name, designer)
    _description = description_text
    _description = _description.gsub(handle, raw_a_href_link) if sub_fabric_collection_name
    _description = _description.gsub(designer.handle, designer.raw_a_href_link)
  end

  # get the description when viewing the fabric collection
  def fabric_collection_description(designer)
    description_with_links(full_description, false, designer)
  end

  # get the description when viewing a product in the fabric collection ... use the abbreviated description, if exists
  def product_description(designer)
    abbreviated_description? ? description_with_links(abbreviated_description, true, designer) : description_with_links(full_description, true, designer)
  end

  # -----------------------------------------------------------------------------

end