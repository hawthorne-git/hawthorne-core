class RefreshMarketplacePricesJob < HawthorneCore::ApplicationJob

  queue_as :low

  # -----------------------------------------------------------------------------------------

  # recalculate every supplier product profile's price on one marketplace (ex: its
  # transaction fee changed); creates missing price rows, and leaves overridden
  # prices alone apart from their calculated price. nothing to do for an inactive marketplace
  def perform(marketplace_id:)
    marketplace = Marketplace.active.find_by(marketplace_id:)
    return if marketplace.nil?

    SupplierProductProfile.includes(:supplier, :product_type, :supplier_product_profile_prices).find_each do |supplier_product_profile|
      supplier_product_profile.refresh_marketplace_price(marketplace)
    rescue => e
      CapturedException.log(location: 'RefreshMarketplacePricesJob', note: { marketplace_id:, supplier_product_profile_id: supplier_product_profile.supplier_product_profile_id }, e:)
    end

    nil
  end

  # -----------------------------------------------------------------------------------------

end
