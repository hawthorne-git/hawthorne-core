# v3.0

module HawthorneCore::Helpers::Email

  # -----------------------------------------------------------------------------

  # determine if the email is used, with the site sharing scope
  def self.taken?(email:) = HawthorneCore::User.exists?(email: email, site_sharing_scope: HawthorneCore::Site.this_site_sharing_scope)

  # -----------------------------------------------------------------------------

  # determine if an email syntax is valid
  def self.syntax_valid?(email:)

    # return false if it does not match its regex
    return false unless email =~ URI::MailTo::EMAIL_REGEXP

    # get the domain of the email - ex: charlieprezzano@gmail.com, domain: gmail.com
    # return false if the domain is blank
    # return false if the domain is included on our internal list, of invalid domains
    domain = email.split('@').last
    return false if domain.blank?
    return false if HawthorneCore::InvalidEmailAddressDomain.invalid?(domain)

    # all validation passed, return true
    true

  end

  # -----------------------------------------------------------------------------

end