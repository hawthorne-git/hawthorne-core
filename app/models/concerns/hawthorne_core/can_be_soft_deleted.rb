# v3.0

module HawthorneCore::CanBeSoftDeleted
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # find records that are active; not marked as deleted
    scope :active, -> { where(deleted: false) }

    # find records that are inactive; marked as deleted
    scope :inactive, -> { where(deleted: true) }

    # ---------------------------------------------------------------------------------

    # mark the record as deleted
    def soft_delete
      update_columns(deleted: true, deleted_at: Time.current)
    end

    # ---------------------------------------------------------------------------------

  end

end