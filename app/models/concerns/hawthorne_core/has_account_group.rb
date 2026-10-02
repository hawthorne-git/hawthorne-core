module HawthorneCore::HasAccountGroup
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # before creating a record, set the records account group attribute
    before_validation :set_account_group, on: :create

    # ---------------------------------------------------------------------------------

    private

    # set the account group
    def set_account_group
      self.account_group = Site.this_site_account_group
    end

    # ---------------------------------------------------------------------------------

  end

end