# v3.0XXX

module HawthorneCore::LinkHelper

  # ----------------------------------------------------------------------------- common

  def parameterize_link(link)
    link.
      gsub(' ', '-').
      gsub('"', '').
      gsub('\'', '').
      gsub('.', '').
      gsub('III', '3').
      gsub('!', '').
      gsub('1/8', 'eighth-inch').
      gsub('1/4', 'quarter-inch').
      gsub('1/2', 'half-inch').
      gsub('25-Strip', '2-and-half-inch-strip').
      gsub('5-Square', '5-inch-square').
      gsub('5-Stacker', '5-inch-stacker').
      gsub('10-Square', '10-inch-square').
      gsub('10-Stacker', '10-inch-stacker').
      downcase
  end

  # ----------------------------------------------------------------------------- designer links

  def designer_link(designer)
    designer_plucked_link(designer.handle, designer.small_web_id)
  end

  def designer_plucked_link(designer_handle, designer_small_web_id)
    link = '/' + designer_handle + '/designer/'
    parameterize_link(link) + designer_small_web_id.upcase
  end

  # ----------------------------------------------------------------------------- fabric collection links

  def fabric_collection_link(fabric_collection)
    fabric_collection_plucked_link(fabric_collection.handle, fabric_collection.small_web_id)
  end

  def fabric_collection_plucked_link(fabric_collection_handle, fabric_collection_small_web_id)
    link = '/' + fabric_collection_handle + '/fabric-collection/'
    parameterize_link(link) + fabric_collection_small_web_id.upcase
  end

  # -----------------------

  def fabric_collection_quick_order_link(fabric_collection)
    fabric_collection_quick_order_plucked_link(fabric_collection.handle, fabric_collection.small_web_id)
  end

  def fabric_collection_quick_order_plucked_link(fabric_collection_handle, fabric_collection_small_web_id)
    link = '/' + fabric_collection_handle + '-fabric-collection/quick-order/'
    parameterize_link(link) + fabric_collection_small_web_id.upcase
  end

  # ----------------------------------------------------------------------------- fabric product links

  # get the fabric product link
  # if available, get the link from the cache and return this value
  # if the link is not in the cache and needs to be set ...
  # in the rare case that the fabric collection for the product is not passed in, find the fabric collection
  # else, create the link, set it into the cache, and return the link
  def fabric_product_link(fabric_collection, fabric_product)
    cache_key = fabric_product.cache_key_link
    Rails.cache.delete(cache_key) if @clear_fragment_cache
    link = Rails.cache.read(cache_key)
    return link unless link.nil?
    fabric_collection = Core::FabricCollection.select(:fabric_collection_id, :handle).find_by(fabric_collection_id: fabric_product.fabric_collection_id) if fabric_collection.nil?
    link = fabric_product_plucked_link(fabric_collection.handle, fabric_product.handle, fabric_product.small_web_id)
    Rails.cache.write(cache_key, link, expires_in: 1.month)
    link
  end

  # create the fabric product link
  def fabric_product_plucked_link(fabric_collection_handle, fabric_product_handle, fabric_product_small_web_id)
    link = '/' + fabric_collection_handle + '/' + fabric_product_handle + '/fabric/'
    parameterize_link(link) + fabric_product_small_web_id.upcase
  end

  # ----------------------------------------------------------------------------- fabric precut product links

  # get the fabric precut product link
  def fabric_precut_product_link(fabric_precut_product)
    fabric_precut_product_plucked_link(fabric_precut_product.handle_for_site, fabric_precut_product.small_web_id)
  end

  # create the fabric product link
  def fabric_precut_product_plucked_link(fabric_precut_product_handle, fabric_product_small_web_id)
    link = '/' + fabric_precut_product_handle + '/fabric-precut/'
    parameterize_link(link) + fabric_product_small_web_id.upcase
  end

  # ----------------------------------------------------------------------------- fabric precut type links

  # create the fabric precut product link
  def fabric_precut_type_plucked_link(fabric_precut_type_id)
    return '/5-inch-stackers' if fabric_precut_type_id == Core::FabricPrecutType.five_inch_square_id
    return '/10-inch-stackers' if fabric_precut_type_id == Core::FabricPrecutType.ten_inch_square_id
    return '/rolie-polies' if fabric_precut_type_id == Core::FabricPrecutType.strip_roll_2_point_5_id
    return '/fat-quarter-bundles' if fabric_precut_type_id == Core::FabricPrecutType.fat_quarter_bundle_id
    return '/half-yard-bundles' if fabric_precut_type_id == Core::FabricPrecutType.half_yard_bundle_id
    return '/full-yard-bundles' if fabric_precut_type_id == Core::FabricPrecutType.full_yard_bundle_id
    raise 'Exception: Unexpected fabric precut id in ApplicationLinkHelper:fabric_precut_type_plucked_link, fabric_precut_type_id = ' + fabric_precut_type_id.to_s
  end

  # -----------------------------------------------------------------------------
  #
  # -----------------------------------------------------------------------------

end
