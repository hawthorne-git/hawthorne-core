module HawthorneCore::Helpers::Email

  # -----------------------------------------------------------------------------

  # determine if the email is used, within the account group
  def self.taken?(email:) = HawthorneCore::User.exists?(email:, account_group: Site.this_site_account_group)

  # -----------------------------------------------------------------------------

  # determine if an email syntax is valid
  def self.syntax_valid?(email:)

    # return false if it does not match its regex
    return false unless email =~ URI::MailTo::EMAIL_REGEXP

    # get the domain of the email - ex: charlieprezzano@gmail.com, domain: gmail.com
    # return false if the domain is blank
    # return false if the domain is included on our internal list, of invalid domains
    domain = Mail::Address.new(email).domain
    return false if domain.blank?
    return false if InvalidEmailDomain.invalid?(domain:)

    # all validation passed, return true
    true

  end

  # -----------------------------------------------------------------------------

end