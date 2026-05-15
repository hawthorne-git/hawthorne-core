class HawthorneCore::InvalidEmailAddressDomain < HawthorneCore::ActiveRecordBaseAdmin

  # -----------------------------------------------------------------------------

  self.table_name = 'invalid_email_domains'
  self.primary_key = 'invalid_email_domain_id'

  def id = invalid_email_domain_id

  # -----------------------------------------------------------------------------

  # determine if the domain is included in our internal list of invalid domains
  def self.invalid?(domain:) = domain.present? && exists?(handle: domain.downcase)

  # -----------------------------------------------------------------------------

end