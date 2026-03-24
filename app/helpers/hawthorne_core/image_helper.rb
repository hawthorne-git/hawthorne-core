# v3.0XXX

module HawthorneCore::ImageHelper

  # ----------------------------------------------------------------

  def generate_random_image_id
    Array.new(12) { Array('A'..'Z').sample }.join
  end

  # ----------------------------------------------------------------

  # returns the active storage variant at specific resize with a specific format
  def resize_to_fit_variant(format, image_resize_width, image_resize_height)
    quality = Rails.env.production? ? 75 : 80
    return { format: :avif, saver: { strip: true, quality: quality }, resize_to_fit: [image_resize_width, image_resize_height] } if format == 'avif'
    return { format: :jpeg, saver: { strip: true, quality: quality }, resize_to_fit: [image_resize_width, image_resize_height] } if format == 'jpeg'
    return { convert: :webp, saver: { strip: true, quality: quality }, resize_to_fit: [image_resize_width, image_resize_height] } if format == 'webp'
    raise 'Exception: Unexpected format, format value = ' + format.to_s
  end

  # ----------------------------------------------------------------

  # returns the url for the variant
  # first, see if the variant is already found and stored in the attribute image_variants (0 database calls)
  # next, find the variant with direct sql (1 database call)
  # else, process the variant on the image  (3 database calls)
  def variant_url(image, image_variants, image_format, image_width, image_height)

    begin

      # create the variant
      variant = resize_to_fit_variant(image_format, image_width, image_height)

      # find via a passed in list of image variants
      variant_key = image_variant_key_from_image_variants(image, image_variants, variant)
      return full_aws_image_url(variant_key) if variant_key

      # find via a direct sql call
      variant_key = image_variant_key(image, variant)
      return full_aws_image_url(variant_key) if variant_key

      # find via processing the image variant
      return trim_aws_image_url(image.variant(variant).processed.url)

    rescue ActiveStorage::FileNotFoundError
      return ''
    end

  end

  def avif_variant_url(image, image_variants, image_width, image_height)
    variant_url(image, image_variants, 'avif', image_width, image_height)
  end

  def jpeg_variant_url(image, image_variants, image_width, image_height)
    variant_url(image, image_variants, 'jpeg', image_width, image_height)
  end

  def webp_variant_url(image, image_variants, image_width, image_height)
    variant_url(image, image_variants, 'webp', image_width, image_height)
  end

  # ----------------------------------------------------------------

  # return the image variant's key via direct sql
  def image_variant_key(image, variant)
    image_blob_id = image.blob.id
    variant_digest = image.variant(variant).variation.digest
    result_set = ActiveRecord::Base.connection.execute("select active_storage_blobs.key from active_storage_variant_records, active_storage_attachments, active_storage_blobs where active_storage_variant_records.blob_id = " + (image_blob_id + 0).to_s + " and active_storage_variant_records.variation_digest = '" + variant_digest + "' and active_storage_attachments.record_id = active_storage_variant_records.id and active_storage_attachments.record_type = 'ActiveStorage::VariantRecord' and active_storage_attachments.name = 'image' and active_storage_blobs.id = active_storage_attachments.blob_id")
    result_set.cmd_tuples.zero? ? nil : result_set[0]['key']
  end

  # for an image, returns all variant digests with its respective key
  # the return is an array of hashes ... where each hash contains a variation_digest and its key
  def image_variant_keys(image)
    image_blob_id = image.blob.id
    result_set = ActiveRecord::Base.connection.execute("select active_storage_variant_records.variation_digest, active_storage_blobs.key from active_storage_variant_records, active_storage_attachments, active_storage_blobs where active_storage_variant_records.blob_id = " + (image_blob_id + 0).to_s + " and active_storage_attachments.record_id = active_storage_variant_records.id and active_storage_attachments.record_type = 'ActiveStorage::VariantRecord' and active_storage_attachments.name = 'image' and active_storage_blobs.id = active_storage_attachments.blob_id")
    hashed_result_set = []
    result_set.each do |row|
      hashed_result_set.push(
        {
          blob_id: image_blob_id,
          variation_digest: row['variation_digest'],
          key: row['key']
        }
      )
    end
    hashed_result_set
  end

  # with a list of image variants ... find the images variant key
  def image_variant_key_from_image_variants(image, image_variants, variant)
    return nil if image_variants.nil?
    variant_digest = image.variant(variant).variation.digest
    image_variant_match = image_variants.select { |obj| (obj[:blob_id] == image.blob.id && obj[:variation_digest] == variant_digest) }
    image_variant_match.size.zero? ? nil : image_variant_match[0][:key]
  end

  # ----------------------------------------------------------------

end