class HawthorneCore::ApplicationJob < ActiveJob::Base

  # ----------------------------------------------------------------

  # for code ease, define the site id
  def site_id = Site.this_site_id

  # ----------------------------------------------------------------

end