# v3.0

class HawthorneCore::UserAddress < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # -----------------------------------------------------------------------------

  self.table_name = 'user_addresses'

  def id = user_address_id

  def to_s = [street_address, street_address_extended, city, state_province, postal_code, country_code_alpha2].reject(&:blank?).join(', ')

  # -----------------------------------------------------------------------------

  # find the country handle
  # ex: code_alpha2 is 'US', return 'United States'
  def country_handle = HawthorneCore::Country.where(code_alpha2: country_code_alpha2).pick(:handle)

  # -----------------------------------------------------------------------------

  # determine if the country within the address is to be shipped to
  def ship_to? = HawthorneCore::Country.ship_to_code_alpha2?(code_alpha2: country_code_alpha2)

  # -----------------------------------------------------------------------------

  # find the users addresses, with active countries shipped to, ordered in importance
  def self.all_for_user(user_id:) = active.where(user_id:).order(last_checkout_selected_at: :desc, created_at: :desc).select(&:ship_to?)

  # find the address, by its token
  def self.find_by_token_with_user_id(user_id:, token:) = active.find_by(user_id:, token:)

  # -----------------------------------------------------------------------------

  # determine if the address, captured is the hash, is identical to an existing active address
  def self.identical?(attrs)
    active.
      where(attrs.except(:token)).
      where.not(token: attrs[:token]).
      exists?
  end

  # -----------------------------------------------------------------------------

  # add the address
  def self.perform_add(attrs:)
    address = HawthorneCore::UserAddress.create!(attrs)
    HawthorneCore::UserAction::Log.add_address(note: attrs.merge(user_address_id: address.id))
  end

  # update the address
  def perform_update(attrs:)
    update!(attrs)
    HawthorneCore::UserAction::Log.update_address(note: attrs.merge(user_address_id:))
  end

  # (soft) delete the address
  def perform_delete
    soft_delete
    HawthorneCore::UserAction::Log.remove_address(note: { user_address_id: })
  end

  # -----------------------------------------------------------------------------

end