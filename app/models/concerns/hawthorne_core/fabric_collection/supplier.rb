module HawthorneCore::FabricCollection::Supplier
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # find the number of fabric collections for riley blake designs ... either released or not released
    def self.riley_blake_designs_all_count
      supplier_count(
        537,
        [true, false]
      )
    end

    # ------------------------

    # find the number of fabric collections for a supplier ... specified if released, not released, or either
    def self.supplier_count(supplier_id, released)
      HawthorneCore::FabricCollection.
        where(supplier_id: supplier_id).
        where(is_released: released).
        where(is_public: true).
        where(is_deleted: false).
        count
    end

    # -----------------------------------------------------------------------------

    # find fabric collections for riley blake designs ... either released or not released, with a specified order
    def self.riley_blake_designs_all(order)
      supplier(
        537,
        [true, false],
        order
      )
    end

    # ------------------------

    # find fabric collections for a supplier ... specified if released, not released, or either, with an order
    def self.supplier(supplier_id, released, order)
      HawthorneCore::FabricCollection.
        select([:fabric_collection_id, :handle, :small_web_id, :is_released, :release_date]).
        where(supplier_id: supplier_id).
        where(is_released: released).
        where(is_public: true).
        where(is_deleted: false).
        order(order).
        load_async
    end

    # -----------------------------------------------------------------------------

  end

end