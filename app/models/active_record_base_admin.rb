class ActiveRecordBaseAdmin < ActiveRecord::Base

  # ----------------------------------------------------------------

  self.abstract_class = true

  # ----------------------------------------------------------------

  connects_to database:
                {
                  reading: :admin_replica,
                  writing: :admin
                }

  # ---------------------------------------------------------------------------------

  def with_reading(&block) = self.class.with_reading(&block)
  def with_writing(&block) = self.class.with_writing(&block)

  class << self
    def with_reading(&block) = ActiveRecordBaseAdmin.connected_to(role: :reading, &block)
    def with_writing(&block) = ActiveRecordBaseAdmin.connected_to(role: :writing, &block)
  end

  # ----------------------------------------------------------------

end