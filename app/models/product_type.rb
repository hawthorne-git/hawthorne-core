class ProductType < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_types'
  self.primary_key = 'product_type_id'

  def id = product_type_id

  # -----------------------------------------------------------------------------

  has_many :supplier_product_profiles

  # when the processing cost or waste rate changes, flag this type's profiles and recalculate their loaded cost in the background
  after_update_commit :refresh_profile_costs, if: -> { saved_change_to_processing_cost_per_unit? || saved_change_to_waste_rate? }

  # -----------------------------------------------------------------------------

  def self.sewing_kit_id = @sewing_kit_id ||= find_by!(handle: 'Sewing Kit').id

  # -----------------------------------------------------------------------------

  # the abbreviation when there is one, else the name (handle)
  def short_name = abbreviation.presence || handle

  # -----------------------------------------------------------------------------

  private

  def refresh_profile_costs
    supplier_product_profiles.update_all(refresh_loaded_cost: true)
    RefreshProfileCostsJob.perform_later
  end

  # -----------------------------------------------------------------------------

end
