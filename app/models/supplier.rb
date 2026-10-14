class Supplier < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # the rates that feed a supplier product profile's landed cost
  LANDED_COST_RATES = %w[discount_rate cc_fee_rate tariff_rate freight_cost_per_lb].freeze

  # -----------------------------------------------------------------------------

  self.table_name = 'suppliers'
  self.primary_key = 'supplier_id'

  def id = supplier_id

  # -----------------------------------------------------------------------------

  has_many :supplier_product_profiles

  # when a landed cost rate changes, flag this supplier's profiles and recalculate them in the background
  # (loaded cost is built on landed cost, so it's flagged too)
  after_update_commit :refresh_profile_costs, if: -> { (saved_changes.keys & LANDED_COST_RATES).any? }

  # -----------------------------------------------------------------------------

  private

  def refresh_profile_costs
    supplier_product_profiles.update_all(refresh_landed_cost: true, refresh_loaded_cost: true)
    RefreshProfileCostsJob.perform_later
  end

  # -----------------------------------------------------------------------------

end
