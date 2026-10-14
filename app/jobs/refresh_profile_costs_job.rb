class RefreshProfileCostsJob < HawthorneCore::ApplicationJob

  queue_as :low

  # -----------------------------------------------------------------------------------------

  # recalculate the landed and loaded cost of every supplier product profile flagged
  # with refresh_landed_cost (ex: its supplier's discount rate changed) or
  # refresh_loaded_cost (ex: its product type's processing cost changed); saving the
  # profile recalculates both and clears both flags
  def perform
    SupplierProductProfile.where(refresh_landed_cost: true).or(SupplierProductProfile.where(refresh_loaded_cost: true))
                          .includes(:supplier, :product_type).find_each do |supplier_product_profile|
      supplier_product_profile.save!
    rescue => e
      CapturedException.log(location: 'RefreshProfileCostsJob', note: { supplier_product_profile_id: supplier_product_profile.supplier_product_profile_id }, e:)
    end

    nil
  end

  # -----------------------------------------------------------------------------------------

end
