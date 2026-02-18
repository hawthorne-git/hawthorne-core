# v3.0

module HawthorneCore

  class ActiveRecordBase < ActiveRecord::Base

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

end