# v3.0

module HawthorneCore::Database
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # used around actions / segments of code,
    # to connect to a read-only database
    def with_reading
      HawthorneCore::ActiveRecordBase.with_reading { yield }
    end

    # ---------------------------------------------------------------------------

    # used around actions / segments of code,
    # to connect to the primary database, for writing
    def with_writing
      HawthorneCore::ActiveRecordBase.with_writing { yield }
    end

    # ---------------------------------------------------------------------------

  end

end