class Marketplace < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # the rates that feed the calculated price of every profile on this marketplace
  PRICE_RATES = %w[transaction_rate margin_multiplier shipping_loss_per_100_grams].freeze

  # -----------------------------------------------------------------------------

  self.table_name = 'marketplaces'
  self.primary_key = 'marketplace_id'

  def id = marketplace_id

  # our own site; the only marketplace with sale and member prices
  HAWTHORNE_ID = 1

  # looked up once per process (the id never changes); saving the hawthorne marketplace clears it in the process
  # that saved it, so its rates stay current there. other running apps keep the loaded rates until restarted
  def self.hawthorne = @hawthorne ||= find_by(marketplace_id: HAWTHORNE_ID)

  def hawthorne? = id == HAWTHORNE_ID

  # -----------------------------------------------------------------------------

  has_many :supplier_product_profile_prices

  after_commit :clear_hawthorne, if: :hawthorne?

  # when a marketplace is added, reactivated, or a price rate changes, recalculate
  # every profile's price on it in the background (one after_commit for both events;
  # separate after_create_commit / after_update_commit on the same method would keep only the last)
  after_commit :refresh_prices, on: [:create, :update], if: -> { previously_new_record? || (saved_changes.keys & (PRICE_RATES + ['deleted'])).any? }

  # -----------------------------------------------------------------------------

  private

  def refresh_prices = RefreshMarketplacePricesJob.perform_later(marketplace_id:)

  def clear_hawthorne = self.class.instance_variable_set(:@hawthorne, nil)

  # -----------------------------------------------------------------------------

end
