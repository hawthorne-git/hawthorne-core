# v3.0

module HawthorneCore::Database
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # used around actions / segments of code,
    # to connect to a read-only database
    def connect_to_read_database
      HawthorneCore::ActiveRecordBase.connected_to(role: :reading) do
        yield
      end
    end

    # ---------------------------------------------------------------------------

    # used around actions / segments of code,
    # to connect to the primary database, for writing
    def connect_to_writing_database
      HawthorneCore::ActiveRecordBase.connected_to(role: :writing) do
        yield
      end
    end

    # ---------------------------------------------------------------------------

  end

end