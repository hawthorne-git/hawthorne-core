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

end