module HawthorneCore

  class Site < HawthorneCore::ActiveRecordBase

    # -----------------------------------------------------------------------------

    self.table_name = 'sites'

    # -----------------------------------------------------------------------------

    include HawthorneCore::Site::Attrs,
            HawthorneCore::Site::RileyBlake

    # -----------------------------------------------------------------------------

    SITE_IDS =
      {
        riley_blake_name => riley_blake_id
      }

    # -----------------------------------------------------------------------------

    # get the environment site name ... if not set, return 'NIL'
    def self.env_site_name
      ENV.key?('SITE_NAME') ? ENV['SITE_NAME'] : 'NIL'
    end

    # in the case where ENV['SITE_NAME'] is not expected,
    # return the raised exception - which includes the method name and ENV['SITE_NAME']
    def self.env_site_name_exception(method_name)
      'Exception: Unexpected ENV["SITE_NAME"] in method HawthorneCore::Site.' + method_name + ', ENV["SITE_NAME"] = "' + env_site_name + '"'
    end

    # -----------------------------------------------------------------------------

    # get the site id using the applications SITE_NAME
    def self.this_site_id
      SITE_IDS.fetch(env_site_name) { raise env_site_name_exception('this_site_id') }
    end

    # -----------------------------------------------------------------------------

  end

end