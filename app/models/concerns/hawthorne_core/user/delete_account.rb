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
    def self.clear_delete_account_attrs(user_id:) = user_site(user_id:).clear_delete_account_attrs

    # set the users delete account attributes, which is site specific, then send the code via email
    def self.set_delete_account_attrs_then_send_it(user_id:) = user_site(user_id:).set_delete_account_attrs_then_send_it

    # -----------------------------------------------------------------------------

    # deletes a user account - set the email and phone number to be their token,
    # clear their delete account attributes
    def delete_account
      soft_delete
      update_columns(email: token, phone_number: token, name: token)
      HawthorneCore::UserAction::Log.account_deleted
      clear_delete_account_attrs
      #TODO: delete the stripe account? maybe once the user does not have an 'open' order
      #TODO: delete all notifications ... follows / newsletter sign-ups
    end
    def self.delete_account(user_id:) = find_by(user_id:).delete_account

    # -----------------------------------------------------------------------------

  end

end