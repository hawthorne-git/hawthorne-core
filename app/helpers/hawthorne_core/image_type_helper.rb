# v3.0XXX

module HawthorneCore::ImageTypeHelper

  # -----------------------------------------------------------------------------

  def product_image_banner_1_max_width_pct(image_type)
    return 45 if image_type == product_thumbnail_image_type
    return 35 if image_type == product_main_image_type
    raise 'Unexpected image type in getting product_image_banner_1_max_width_pct, image_type: ' + image_type
  end

  def product_image_banner_2_max_width_pct(image_type)
    return 50 if image_type == product_main_image_type
    raise 'Unexpected image type in getting product_image_banner_2_max_width_pct, image_type: ' + image_type
  end

  def product_image_banner_sale_max_width_pct(image_type)
    return 28 if image_type == product_thumbnail_image_type
    raise 'Unexpected image type in getting product_image_banner_sale_max_width_pct, image_type: ' + image_type
  end

  # -----------------------------------------------------------------------------

  # set the designer bio image attrs
  # NOTE: if changing value, update CSS --designer_bio_image_width_height

  def designer_bio_image_type
    'designer_bio_image'
  end

  def designer_bio_image_loading
    :eager
  end

  def designer_bio_image_width_height
    450
  end

  # -----------------------------------------------------------------------------

  # set the designer bio preview image attrs
  # NOTE: if changing value, update CSS --designer_bio_preview_image_width_height

  def designer_bio_preview_image_type
    'designer_bio_preview_image'
  end

  def designer_bio_preview_image_loading
    :lazy
  end

  def designer_bio_preview_image_width_height
    450
  end

  # -----------------------------------------------------------------------------

  # set the fabric collection poster image attrs
  # NOTE: if changing value, update CSS --fabric_collection_poster_image_width and --fabric_collection_poster_image_height

  def fabric_collection_poster_image_type
    'fabric_collection_poster_image'
  end

  def fabric_collection_poster_image_loading
    :eager
  end

  def fabric_collection_poster_image_width
    1280
  end

  def fabric_collection_poster_image_height
    752
  end

  # -----------------------

  # set the fabric collection preview image attrs
  # NOTE: if changing value, update CSS --fabric_collection_preview_image_width and --fabric_collection_preview_image_height

  def fabric_collection_preview_image_type
    'fabric_collection_preview_image'
  end

  def fabric_collection_preview_image_loading
    :lazy
  end

  def fabric_collection_preview_image_width
    600
  end

  def fabric_collection_preview_image_height
    473
  end

  # -----------------------------------------------------------------------------

  # set the fabric precut type poster image attrs
  # NOTE: if changing value, update CSS --fabric_precut_type_poster_image_width and --fabric_precut_type_poster_image_height

  def fabric_precut_type_poster_image_type
    'fabric_precut_type_poster_image'
  end

  def fabric_precut_type_poster_image_loading
    :eager
  end

  def fabric_precut_type_poster_image_width
    1280
  end

  def fabric_precut_type_poster_image_height
    278
  end

  # -----------------------------------------------------------------------------

  # set the fabric precut type thumbnail image attrs
  # NOTE: if changing value, update CSS --fabric_precut_type_thumbnail_image_width and --fabric_precut_type_thumbnail_image_height

  def fabric_precut_type_thumbnail_image_type
    'fabric_precut_type_thumbnail_image'
  end

  def fabric_precut_type_thumbnail_image_loading
    :lazy
  end

  def fabric_precut_type_thumbnail_image_width
    1280
  end

  def fabric_precut_type_thumbnail_image_height
    278
  end

  # -----------------------------------------------------------------------------

  # set the product main image attrs
  # NOTE: if changing value, update CSS --product_main_image_width_height

  def product_main_image_type
    'product_main_image'
  end

  def product_main_image_loading
    :eager
  end

  def product_main_image_width_height
    600
  end

  # -----------------------

  # set the product main supporting image attrs

  def product_main_supporting_image_type
    'product_main_supporting_image'
  end

  def product_main_supporting_image_loading
    :eager
  end

  def product_main_supporting_image_width_height
    600
  end

  # -----------------------

  # set the product thumbnail image attrs
  # NOTE: if changing value, update CSS --product_image_thumbnail_width_height

  def product_thumbnail_image_type
    'product_thumbnail_image'
  end

  def product_thumbnail_image_loading
    :lazy
  end

  def product_thumbnail_image_width_height
    225
  end

  # -----------------------------------------------------------------------------

  def image_type_loading(image_type)
    return designer_bio_image_loading if image_type == designer_bio_image_type
    return designer_bio_preview_image_loading if image_type == designer_bio_preview_image_type
    return fabric_collection_poster_image_loading if image_type == fabric_collection_poster_image_type
    return fabric_collection_preview_image_loading if image_type == fabric_collection_preview_image_type
    return fabric_precut_type_poster_image_loading if image_type == fabric_precut_type_poster_image_type
    return fabric_precut_type_thumbnail_image_loading if image_type == fabric_precut_type_thumbnail_image_type
    return product_main_image_loading if image_type == product_main_image_type
    return product_main_supporting_image_loading if image_type == product_main_supporting_image_type
    return product_thumbnail_image_loading if image_type == product_thumbnail_image_type
    raise 'Unexpected image type in setting image loading, image_type: ' + image_type
  end

  def image_type_width_height(image_type)
    return { width: designer_bio_image_width_height, height: designer_bio_image_width_height } if image_type == designer_bio_image_type
    return { width: designer_bio_preview_image_width_height, height: designer_bio_preview_image_width_height } if image_type == designer_bio_preview_image_type
    return { width: fabric_collection_poster_image_width, height: fabric_collection_poster_image_height } if image_type == fabric_collection_poster_image_type
    return { width: fabric_collection_preview_image_width, height: fabric_collection_preview_image_height } if image_type == fabric_collection_preview_image_type
    return { width: fabric_precut_type_poster_image_width, height: fabric_precut_type_poster_image_height } if image_type == fabric_precut_type_poster_image_type
    return { width: fabric_precut_type_thumbnail_image_width, height: fabric_precut_type_thumbnail_image_height } if image_type == fabric_precut_type_thumbnail_image_type
    return { width: product_main_image_width_height, height: product_main_image_width_height } if image_type == product_main_image_type
    return { width: product_main_supporting_image_width_height, height: product_main_supporting_image_width_height } if image_type == product_main_supporting_image_type
    return { width: product_thumbnail_image_width_height, height: product_thumbnail_image_width_height } if image_type == product_thumbnail_image_type
    raise 'Unexpected image type in setting image width / height, image_type: ' + image_type
  end

  # -----------------------------------------------------------------------------

end