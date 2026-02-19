# v3.0

class HawthorneCore::Site < HawthorneCore::ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'sites'

  # -----------------------------------------------------------------------------

  include HawthorneCore::Site::Attrs,
          HawthorneCore::Site::RileyBlake

  # -----------------------------------------------------------------------------

  # define the list of site ids
  SITE_IDS =
    {
      riley_blake_name => riley_blake_id
    }

  # -----------------------------------------------------------------------------

  # get the site id, from the ENV attribute SITE_NAME ... if not found, raise an exception
  def self.this_site_id
    SITE_IDS.fetch(HawthorneCore::AppConfig.site_name) { raise env_site_name_exception('this_site_id') }
  end

  # -----------------------------------------------------------------------------

  private

  # in the case where site name is not expected,
  # return the raised exception - which includes the method name and ENV['SITE_NAME']
  def self.env_site_name_exception(method_name)
    'Exception: Unexpected ENV["SITE_NAME"] in method HawthorneCore::Site.' + method_name + ', ENV["SITE_NAME"] = "' + HawthorneCore::AppConfig.site_name + '"'
  end

  # -----------------------------------------------------------------------------

end