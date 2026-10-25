class Product < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # a product image's role comes from its image type (by handle): one main image (what hawthorne shows, ex: a lifestyle
  # photo), at most one supplier main image (the supplier's own, ex: a flat image), any number of additional images in
  # order (product_images.order_nbr), and for a sewing kit, at most one requirements image (what's needed to make it)
  MAIN_IMAGE_TYPE = 'Product / Main'
  SUPPLIER_MAIN_IMAGE_TYPE = 'Product / Main / Supplier'
  ADDITIONAL_IMAGE_TYPE = 'Product / Additional'
  SEWING_KIT_REQUIREMENTS_IMAGE_TYPE = 'Product / Sewing Kit / Requirements'

  # -----------------------------------------------------------------------------

  self.table_name = 'products'
  self.primary_key = 'product_id'

  def id = product_id

  # the storefront url's path segment: the name for people / search engines, then the token, which does the lookup
  # (ex: acorn-and-amber-oak-grove-quilt-kit-rtym372n6r9t). not to_param, which stays the id for the admin's routes
  def url_slug = "#{handle.parameterize}-#{token.downcase}"

  # -----------------------------------------------------------------------------

  # pricing comes from the profile (required: see the validation below, which names it on the form)
  belongs_to :supplier_product_profile, optional: true
  belongs_to :product_type
  belongs_to :supplier
  belongs_to :artist, optional: true

  has_many :product_images, -> { order(:order_nbr) }
  has_many :images, through: :product_images

  # the product form's image uploads (not stored on products; see the image roles above)
  attr_accessor :main_image_file, :supplier_main_image_file, :additional_image_files, :sewing_kit_requirements_image_file

  # supplier_id / product_type_id always follow the profile (kept on products for queries)
  before_validation :copy_from_supplier_product_profile

  # rules that depend on other records (the profile's current price, the type's current attributes) are only checked
  # when this product's own values change, so a later price drop or a newly required attribute never blocks an
  # unrelated save (ex: inactivating it, or changing its inventory)

  validates :supplier_product_profile, presence: true

  # choosing a profile for an active product: it must be active (activating a product activates its profile instead)
  validate :supplier_product_profile_active, if: -> { active? && supplier_product_profile_id_changed? }

  # the sale price is advertised on hawthorne, so it must beat the regular price; it may go below MAP, even while
  # adhering to it
  validate :sale_price_allowed, if: -> { sale_price_changed? || supplier_product_profile_id_changed? }

  # attrs holds the product type's attributes (see ProductTypeAttr), keyed by attr key; each value must fit its data type
  validate :attrs_match_product_type, if: -> { attrs_changed? || product_type_id_changed? }

  # a GTIN identifies one product (products_uk_gtin)
  validate :gtin_unique, if: -> { gtin.present? && gtin_changed? }

  # an active product needs an active profile, so activating a product activates its profile too
  after_save :activate_supplier_product_profile, if: -> { saved_change_to_deleted?(from: true, to: false) }

  # an active sewing kit with no Project set gets one from its supplier main image (see Ai::SewingKitProjectJob); also
  # queued as a supplier main image is added (see ProductImage), since a form saves its images after the product
  after_commit -> { Ai::SewingKitProjectJob.perform_later(product_id:) }, on: [:create, :update], if: :project_classifiable?

  # an active sewing kit's search text is written again as what it's written from changes (see Ai::ProductSearchTextJob,
  # which skips one whose search text is up to date); also queued as its supplier main image is added or described
  after_commit -> { Ai::ProductSearchTextJob.perform_later(product_id:) }, on: [:create, :update], if: :search_text_source_changed?

  # -----------------------------------------------------------------------------

  # the images by role (see MAIN_IMAGE_TYPE); each works off preloaded product_images: { image: :image_type } when present
  def main_image = product_images_of_type(MAIN_IMAGE_TYPE).first&.image

  def supplier_main_image = product_images_of_type(SUPPLIER_MAIN_IMAGE_TYPE).first&.image

  def additional_images = product_images_of_type(ADDITIONAL_IMAGE_TYPE).map(&:image)

  def sewing_kit_requirements_image = product_images_of_type(SEWING_KIT_REQUIREMENTS_IMAGE_TYPE).first&.image

  # the active product images (with active images) of an image type, by order
  def product_images_of_type(image_type_handle)
    product_images.select do |product_image|
      product_image.active? && product_image.image.active? && product_image.image.image_type&.handle == image_type_handle
    end
  end

  # -----------------------------------------------------------------------------

  # the list price on a marketplace: the profile's price there (nil without a profile / price)
  def list_price_for(marketplace) = marketplace && supplier_product_profile&.price_for(marketplace)

  # the regular (advertised) price on hawthorne; pass the hawthorne marketplace when
  # pricing many products, to avoid looking it up each time
  def hawthorne_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.hawthorne_price(hawthorne)

  # on sale (hawthorne only) when a sale price is set below the regular price
  def on_sale?(hawthorne = Marketplace.hawthorne)
    regular = hawthorne_price(hawthorne)
    sale_price.present? && regular.present? && sale_price < regular
  end

  # the logged in price on hawthorne, from the profile's hawthorne price (may be below MAP)
  def member_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.member_price_or_default(hawthorne)

  # the hawthorne price when presold, from the profile's hawthorne preorder discount (nil without one)
  def preorder_price(hawthorne = Marketplace.hawthorne) = supplier_product_profile&.preorder_price(hawthorne)

  # the price a hawthorne shopper sees: the lowest of the regular price, the sale
  # price (when on sale), the member price (when logged in), and the preorder price
  # (when the product is being presold)
  def price_for_shopper(logged_in:, preorder: false, hawthorne: Marketplace.hawthorne)
    prices = [hawthorne_price(hawthorne)]
    prices << sale_price if on_sale?(hawthorne)
    prices << member_price(hawthorne) if logged_in
    prices << preorder_price(hawthorne) if preorder
    prices.compact.min
  end

  # -----------------------------------------------------------------------------

  def sewing_kit? = product_type_id == ProductType.sewing_kit_id

  # whether the last save changed what an active sewing kit's search text is written from (see Ai::ProductSearchTextJob)
  def search_text_source_changed?
    active? && sewing_kit? && update_search_text_with_ai? &&
      %w[handle description attrs supplier_id product_type_id deleted].any? { |column| saved_change_to_attribute?(column) }
  end

  # whether any is on hand (the same test as the admin's product list)
  def in_stock? = inventory_on_hand.to_d.positive?

  # an active sewing kit with no Project set, so one can be set from its supplier main image (see Ai::SewingKitProjectJob)
  def project_classifiable? = active? && sewing_kit? && attr_value(:project).blank?

  # a product type attribute's value (ex: attr_value(:width) => 42.5); nil when not set
  def attr_value(key) = (attrs || {})[key.to_s]

  # set attrs from a form's values (strings, keyed by attr key), typed for each of the product type's attributes:
  # "42.5" => 42.5, "1" => true, a MultiSelect's list of values; a blank value is left out. a value that isn't valid
  # for its type is kept as typed, so validation reports it
  def assign_form_attrs(form_values)
    form_values = form_values.to_h.stringify_keys
    self.attrs = (product_type&.product_type_attrs&.includes(:product_attr) || []).each_with_object({}) do |type_attr, result|
      value = cast_form_attr(type_attr.data_type, form_values[type_attr.key])
      result[type_attr.key] = value unless value.nil?
    end
  end

  # -----------------------------------------------------------------------------

  private

  def cast_form_attr(data_type, raw)
    return nil if raw.nil?

    case data_type
    when 'Boolean' then ActiveModel::Type::Boolean.new.cast(raw) || false
    when 'MultiSelect' then Array(raw).map(&:to_s).compact_blank.uniq.presence
    else
      text = raw.to_s.strip
      return nil if text.empty?

      case data_type
      when 'Integer', 'Reference' then Integer(text, 10, exception: false) || text
      when 'Decimal' then Float(text, exception: false) || text
      else text
      end
    end
  end

  def attrs_match_product_type
    return if product_type.nil?

    values = attrs || {}
    type_attrs = product_type.product_type_attrs.includes(:product_attr, :product_type_attr_options).index_by(&:key)

    (values.keys - type_attrs.keys).each { |key| errors.add(:attrs, "#{key} isn't an attribute of #{product_type.handle}") }

    type_attrs.each do |key, type_attr|
      value = values[key]
      if value.nil? || value == '' || value == []
        errors.add(:attrs, "#{type_attr.handle} is required") if type_attr.required?
        next
      end

      problem = attr_value_problem(type_attr, value)
      errors.add(:attrs, "#{type_attr.handle} #{problem}") if problem
    end
  end

  # what's wrong with a value for its attr's data type (nil when it's fine)
  def attr_value_problem(type_attr, value)
    case type_attr.data_type
    when 'Text' then 'must be text' unless value.is_a?(String)
    when 'Boolean' then 'must be yes or no' unless [true, false].include?(value)
    when 'Integer' then 'must be a whole number' unless value.is_a?(Integer)
    when 'Decimal' then 'must be a number' unless value.is_a?(Numeric)
    when 'Select' then "must be one of: #{type_attr.option_values.join(', ')}" unless type_attr.option_values.include?(value)
    when 'MultiSelect'
      "must be a list of: #{type_attr.option_values.join(', ')}" unless value.is_a?(Array) && value == value.uniq && (value - type_attr.option_values).empty?
    when 'Reference' then 'must be an existing record' unless value.is_a?(Integer) && type_attr.reference_model&.exists?(value)
    end
  end

  def copy_from_supplier_product_profile
    return if supplier_product_profile.nil?

    self.supplier_id = supplier_product_profile.supplier_id
    self.product_type_id = supplier_product_profile.product_type_id
  end

  def activate_supplier_product_profile
    supplier_product_profile.activate if supplier_product_profile&.deleted?
  end

  def supplier_product_profile_active
    errors.add(:supplier_product_profile, 'is inactive') if supplier_product_profile&.deleted?
  end

  def sale_price_allowed
    return if sale_price.nil? || supplier_product_profile.nil?

    regular = hawthorne_price
    errors.add(:sale_price, "must be below the regular Hawthorne price (#{format_price(regular)})") if regular && sale_price >= regular
  end

  def gtin_unique
    errors.add(:base, 'GTIN already exists') if Product.where(gtin:).where.not(product_id:).exists?
  end

  def format_price(value) = ActiveSupport::NumberHelper.number_to_currency(value)

end
