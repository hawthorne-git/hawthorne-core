# v3.0

class HawthorneCore::ApplicationJob < ActiveJob::Base

  # ----------------------------------------------------------------

  # for code ease, define the site id
  def site_id = HawthorneCore::Site.this_site_id

  # ----------------------------------------------------------------

end