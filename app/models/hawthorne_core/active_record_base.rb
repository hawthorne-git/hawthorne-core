# v3.0

class HawthorneCore::ActiveRecordBase < ActiveRecord::Base

  # ----------------------------------------------------------------

  self.abstract_class = true

  # ----------------------------------------------------------------

  connects_to database:
                {
                  writing: :primary,
                  reading: :primary_replica,
                }

  # ----------------------------------------------------------------

  def with_reading(&block) = self.class.with_reading(&block)
  def with_writing(&block) = self.class.with_writing(&block)

  class << self
    def with_reading(&block) = HawthorneCore::ActiveRecordBase.connected_to(role: :reading, &block)
    def with_writing(&block) = HawthorneCore::ActiveRecordBase.connected_to(role: :writing, &block)
  end

  # ----------------------------------------------------------------

end