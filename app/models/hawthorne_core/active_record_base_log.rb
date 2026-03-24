# v3.0

class HawthorneCore::ActiveRecordBaseLog < ActiveRecord::Base

  # ----------------------------------------------------------------

  self.abstract_class = true

  # ----------------------------------------------------------------

  connects_to database:
                {
                  reading: :log_replica,
                  writing: :log
                }

  # ----------------------------------------------------------------

  def with_reading(&block) = self.class.with_reading(&block)
  def with_writing(&block) = self.class.with_writing(&block)

  class << self
    def with_reading(&block) = HawthorneCore::ActiveRecordBaseLog.connected_to(role: :reading, &block)
    def with_writing(&block) = HawthorneCore::ActiveRecordBaseLog.connected_to(role: :writing, &block)
  end

  # ----------------------------------------------------------------

end