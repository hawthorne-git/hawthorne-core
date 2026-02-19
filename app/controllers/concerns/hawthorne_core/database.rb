# v3.0

module HawthorneCore
  module Database
    extend ActiveSupport::Concern

    included do

      # ---------------------------------------------------------------------------

      # used around actions / segments of code,
      # to connect to a read-only database
      def connect_to_read_database
        HawthorneCore::ActiveRecordBase.connected_to(role: :reading) { yield }
      end

      # ---------------------------------------------------------------------------

      # used around actions / segments of code,
      # to connect to the primary database, for writing
      def connect_to_writing_database
        HawthorneCore::ActiveRecordBase.connected_to(role: :writing) { yield }
      end

      # ---------------------------------------------------------------------------

    end

  end
end