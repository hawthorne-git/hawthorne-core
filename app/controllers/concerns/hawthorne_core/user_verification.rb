# v3.0XXX

module HawthorneCore::UserVerification
  extend ActiveSupport::Concern

  included do

    # --------------------------------------------------------------------------- Email Address: Syntax

    # determine if an email address syntax is valid
    def email_address_syntax_valid?(email_address)

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

    # --------------------------------------------------------------------------- Phone Number: Syntax

    # determine if a phone number is valid - US / CANADA ONLY
    def phone_number_valid?(phone_number)
      digits = phone_number.to_s.gsub(/\D/, '')
      digits = digits[1..] if digits.length == 11 && digits.start_with?('1')
      digits.length == 10
    end

    # --------------------------------------------------------------------------- Signed In / Out

    # validates that the site user is signed in
    # if not, the user is redirected to the sign-in page
    def verify_signed_in?
      redirect_to sign_in_path unless @signed_in
    end

    # validates that the site user is signed out
    # if not, the user is redirected to their account page
    def verify_signed_out?
      redirect_to account_path if @signed_in
    end

    # ---------------------------------------------------------------------------

  end

end