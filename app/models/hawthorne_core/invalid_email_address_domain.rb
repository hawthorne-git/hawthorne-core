# v3.0

class HawthorneCore::InvalidEmailAddressDomain < HawthorneCore::ActiveRecordBase

  # -----------------------------------------------------------------------------

  self.table_name = 'invalid_email_address_domains'

  # -----------------------------------------------------------------------------

  # determine if the domain is included in our internal list of invalid domains
  def self.invalid?(domain)
    exists?(invalid_domain: domain.downcase)
  end

  # -----------------------------------------------------------------------------

end