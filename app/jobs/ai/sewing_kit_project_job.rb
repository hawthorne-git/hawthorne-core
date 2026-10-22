module Ai
  # sets a sewing kit's Project attr (ex: quilt, table runner) from its supplier main image, asking Jev which of the
  # Project options (Sewing Kit's active ones, so adding an option needs no code change) the cover image shows. only a
  # kit with no Project set is classified; a low confidence answer leaves it unset (Unknown), to be set on the form
  class SewingKitProjectJob < HawthorneCore::ApplicationJob

    queue_as :low

    PROJECT_KEY = 'project'

    # below this, Jev's answer is too unsure to set
    MIN_CONFIDENCE = 0.7

    INSTRUCTIONS = 'Analyze the image, which type of sewing kit is this based on the cover image?'

    # -----------------------------------------------------------------------------------------

    def perform(product_id:)
      product = Product.includes(product_images: { image: [:image_type, { file_attachment: :blob }] }).find_by(product_id:)
      return unless product && classify?(product)

      image = product.supplier_main_image
      return unless image&.file&.attached?

      options = project_options
      return if options.empty?

      # the product name goes with the image (the cover images share one template, so the name tells a table runner
      # from a quilt)
      answer = Services::TypeSafeSvc.new.image_choice(
        image_bytes: image.file.download,
        instructions: INSTRUCTIONS,
        criteria: options.to_h { |option| [option.value, option.handle] },
        context: "Product name: #{product.handle}"
      )

      choice = answer['choice']
      return unless options.any? { |option| option.value == choice } && answer['confidence'].to_f >= MIN_CONFIDENCE

      # saved again in case the kit changed while Jev was asked (ex: a Project was set on the form)
      product.reload
      return unless classify?(product)

      product.update!(attrs: (product.attrs || {}).merge(PROJECT_KEY => choice))

    rescue => e
      CapturedException.log(location: 'Ai::SewingKitProjectJob', note: { product_id:, answer: }, e:)
    end

    # -----------------------------------------------------------------------------------------

    private

    # an active sewing kit with no Project set
    def classify?(product)
      product.active? && product.product_type_id == ProductType.sewing_kit_id && product.attr_value(PROJECT_KEY).blank?
    end

    # Sewing Kit's active Project options, in order (none when Sewing Kit has no Project attr)
    def project_options
      type_attr = ProductType.find(ProductType.sewing_kit_id).product_type_attrs.includes(:product_attr, :product_type_attr_options)
                             .find { |product_type_attr| product_type_attr.key == PROJECT_KEY }
      type_attr ? type_attr.product_type_attr_options.select(&:active?) : []
    end

    # -----------------------------------------------------------------------------------------

  end
end
