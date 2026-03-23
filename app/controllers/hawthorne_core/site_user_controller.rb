# v3.0XXX

class HawthorneCore::SiteUserController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  before_action :validate_signed_in?, only: [
    :show
  ]

  # ----------------------------------------------------------------------------- Show (Account)

  # show the users account
  def show

    # ----------------------

    # determine which database to connect to
    # the primary database is used after adding / deleting a credit card or shipping address
    #connect_to_role = session[:use_primary_db].present? ? primary_database_role : follower_database_role
    session.delete(:use_primary_db) if session[:use_primary_db].present?
    HawthorneCore::ActiveRecordBase.connected_to(role: :writing) do

      # get the site_user
      @user = Core::User.
        select(:email_address, :full_name, :phone_number).
        find_by(site_user_id: session[:site_user_id], site_id: Core::Site.this_site_shared_ids)

      # get all the users active credit cards
      @credit_cards = Core::UserCreditCard.
        select(:site_user_credit_card_id, :braintree_id).
        where(site_user_id: session[:site_user_id]).
        where(deleted: false).
        order(created_at: :desc)

      # get all the users active shipping addresses
      @shipping_addresses = Core::UserShippingAddress.
        select(:site_user_shipping_address_id, :token, :full_name, :street_address, :street_address_extended, :city, :state_province, :postal_code, :country).
        where(site_user_id: session[:site_user_id]).
        where(deleted: false).
        order(created_at: :desc)

    end

    # ----------------------

    @html_title = 'My Account'

    # ----------------------

  end

  # -----------------------------------------------------------------------------

end