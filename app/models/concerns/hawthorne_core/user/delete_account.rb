# v3.0

module HawthorneCore::User::DeleteAccount
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if a specific user id is deleted
    def self.deleted?(user_id:) = exists?(user_id:, deleted: true)

    # -----------------------------------------------------------------------------

    # clear the users delete account attributes, which is site specific
    def clear_delete_account_attrs = user_site.clear_delete_account_attrs

    # set the users delete account attributes, which is site specific
    def set_delete_account_attrs = user_site.set_delete_account_attrs

    # -----------------------------------------------------------------------------

    # deletes a user account - set the email address to be their token,
    # clear their new email attributes
    def delete_account
      soft_delete
      update_columns(email: token)
      HawthorneCore::UserAction::Log.account_deleted
      clear_delete_account_attrs
      #TODO: delete the stripe account? maybe once the user does not have an 'open' order
      #TODO: delete all notifications ... follows / newsletter sign-ups
    end

    # -----------------------------------------------------------------------------

  end

end