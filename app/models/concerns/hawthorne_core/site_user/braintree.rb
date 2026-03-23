# v3.0

module HawthorneCore::SiteUser::Braintree
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def braintree_account? = braintree_id.present?

    # -----------------------------------------------------------------------------

    # create a braintree customer account for the user ... if not previously created
    def create_braintree_account
      return if braintree_account?
      HawthorneCore::Services::BraintreeSvc.create_user(id)
    end

    # -----------------------------------------------------------------------------

    # attach a braintree customer id to the user
    def attach_braintree_customer_id(braintree_id)
      with_writing { update!(braintree_id: braintree_id) }
      HawthorneCore::SiteUserAction::Log.braintree_customer_id_attached(id, { braintree_id: braintree_id, email_address: email_address })
    end

    # -----------------------------------------------------------------------------

  end

end