class HawthorneCore::UserAddress < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'user_addresses'
  self.primary_key = 'user_address_id'

  def id = user_address_id

  def to_s = [street_address, street_address_extended, city, state_province, postal_code, country_code_alpha2].reject(&:blank?).join(', ')

  # -----------------------------------------------------------------------------

  # determine if an address is marked as default
  def default? = default

  # -----------------------------------------------------------------------------

  # find the country handle
  # ex: code_alpha2 is 'US', return 'United States'
  def country_handle = HawthorneCore::Country.where(code_alpha2: country_code_alpha2).pick(:handle)

  # -----------------------------------------------------------------------------

  # determine if the country within the address is to be shipped to
  def ship_to? = HawthorneCore::Country.ship_to_code_alpha2?(code_alpha2: country_code_alpha2)

  # -----------------------------------------------------------------------------

  # determine if the user has a defaulted address
  def self.default_exists?(user_id) = active.exists?(user_id:, default: true)

  # determine if the user has any (active) addresses
  def self.has_address?(user_id:) = active.where(user_id:).exists?

  # determine if the user has more than one (active) address
  def self.has_more_than_one_address?(user_id:) = active.where(user_id:).count > 1

  # determine if the user has more than one (active or inactive) default address
  def self.more_than_one_default_addresses?(user_id:) = where(user_id:, default: true).count > 1

  # determine if the user has no (active) default address
  def self.no_default_address?(user_id:) = !active.where(user_id:, default: true).exists?

  # determine if the user has one (active) default address
  def self.one_default_address?(user_id:) = where(user_id:, default: true).count == 1

  # set all addresses as not defaulted
  def self.set_all_addresses_as_not_defaulted(user_id:) = where(user_id:).update_all(default: false)

  # set the address last used at checkout / created at, as the default
  # return the token of the address set as default
  def self.set_last_used_or_created_as_default(user_id:)
    address = active.where(user_id:).order(Arel.sql("last_checkout_selected_at DESC NULLS LAST"), created_at: :desc).first
    address&.update(default: true)
    address.token
  end

  # -----------------------------------------------------------------------------

  # clean up a users defaulted addresses
  # exit if the user does not have any (active) addresses
  # if the user has more than one (active or inactive) address defaulted - which should not happen, set all as not defaulted
  # if the user has no (active) address defaulted, set all as not defaulted
  # return if the user has one (active) address defaulted - this is the expected scenario
  # if there is NOT an address defaulted, set the address last used at checkout / last created as the default
  # lastly, return is if there was a change
  def self.clean_defaulted(user_id:)
    return { change_made: false } unless has_address?(user_id:)
    set_all_addresses_as_not_defaulted(user_id:) if more_than_one_default_addresses?(user_id:)
    set_all_addresses_as_not_defaulted(user_id:) if no_default_address?(user_id:)
    return { change_made: false } if one_default_address?(user_id:)
    { change_made: true, token: set_last_used_or_created_as_default(user_id:) }
  end

  # -----------------------------------------------------------------------------

  # find the users addresses, with active countries shipped to, ordered in importance
  # prior to finding, clean defaults
  def self.all_for_user(user_id:)
    clean_defaulted(user_id:)
    active.where(user_id:).order(default: :desc, last_checkout_selected_at: :desc, created_at: :desc).select(&:ship_to?)
  end

  # find the address, by its token
  def self.find_by_token_with_user_id(user_id:, token:) = active.find_by(user_id:, token:)

  # -----------------------------------------------------------------------------

  # determine if the address, captured is the hash, is identical to an existing active address
  def self.identical?(attrs)
    active.
      where(attrs.except(:token, :default)).
      where.not(token: attrs[:token]).
      exists?
  end

  # -----------------------------------------------------------------------------

  # set the address as the default - while first setting all as not defaulted
  def set_as_default
    HawthorneCore::UserAddress.set_all_addresses_as_not_defaulted(user_id:)
    update(default: true)
    HawthorneCore::UserAction::Log.update_address(note: { message: 'Set as default', user_address_id: })
  end

  # -----------------------------------------------------------------------------

  # add the address - if the address is marked to be the users default address, clear current default
  def self.perform_add(attrs:)
    set_all_addresses_as_not_defaulted(user_id: attrs[:user_id]) if attrs[:default]
    address = HawthorneCore::UserAddress.create!(attrs)
    HawthorneCore::UserAction::Log.add_address(note: attrs.merge(user_address_id: address.id))
    address
  end

  # update the address - if the address is marked to be the users default address (and it's not the current default), clear current default
  def perform_update(attrs:)
    HawthorneCore::UserAddress.set_all_addresses_as_not_defaulted(user_id:) if attrs[:default] && !default?
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