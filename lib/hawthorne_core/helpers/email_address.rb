# v3.0

module HawthorneCore::Helpers::EmailAddress

  # -----------------------------------------------------------------------------

  def self.taken?(email_address) = HawthorneCore::User.exists?(email_address: email_address)

  # -----------------------------------------------------------------------------

  # determine if an email address syntax is valid
  def self.syntax_valid?(email_address)

    # return false if it does not match its regex
    return false unless email_address =~ URI::MailTo::EMAIL_REGEXP

    # get the domain of the email address - ex: charlieprezzano@gmail.com, domain: gmail.com
    # return false if the domain is blank
    # return false if the domain is included on our internal list, of invalid domains
    domain = email_address.split('@').last
    return false if domain.blank?
    return false if HawthorneCore::InvalidEmailAddressDomain.invalid?(domain)

    # all validation passed, return true
    true

  end

  # -----------------------------------------------------------------------------

end