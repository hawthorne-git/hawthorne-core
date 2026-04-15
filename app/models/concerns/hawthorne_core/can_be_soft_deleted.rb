# v3.0

module HawthorneCore::CanBeSoftDeleted
  extend ActiveSupport::Concern

  included do

    scope :active, -> { where(deleted: false) }

    scope :inactive, -> { where(deleted: true) }

    # ---------------------------------------------------------------------------------

    # mark the record as soft deleted ... set the deleted attribute to true
    def soft_delete
      update_columns(deleted: true, deleted_at: Time.current)
    end

    # ---------------------------------------------------------------------------------

  end

end