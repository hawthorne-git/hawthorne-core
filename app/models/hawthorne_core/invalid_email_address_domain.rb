# v3.0

class HawthorneCore::InvalidEmailAddressDomain < HawthorneCore::ActiveRecordBaseAdmin

  # -----------------------------------------------------------------------------

  self.table_name = 'invalid_email_domains'

  def id = invalid_email_domain_id

  # -----------------------------------------------------------------------------

  # determine if the domain is included in our internal list of invalid domains
  def self.invalid?(domain) = domain.present? && exists?(handle: domain.downcase)

  # -----------------------------------------------------------------------------

end