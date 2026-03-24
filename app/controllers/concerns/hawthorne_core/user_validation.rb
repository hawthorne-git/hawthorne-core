# v3.0XXX

module HawthorneCore::UserValidation
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

    # --------------------------------------------------------------------------- Phone Number

    # determine if a phone number is valid - US / CANADA ONLY
    def phone_number_valid?(phone_number)
      digits = phone_number.to_s.gsub(/\D/, '')
      digits = digits[1..] if digits.length == 11 && digits.start_with?('1')
      digits.length == 10
    end

    # determine if a phone number is invalid - US / CANADA ONLY
    def phone_number_invalid?(phone_number) = !phone_number_valid?(phone_number)

    # --------------------------------------------------------------------------- Validate: Signed In / Out

    # validates that the site user is signed-in
    # if not, redirect the site user to the login page
    def validate_signed_in?
      redirect_to sign_in_path unless @signed_in
    end

    # validates that the site user is signed-out ()
    # if not, redirect the site user to the logout action
    def validate_signed_out?
      redirect_to sign_out_path if @signed_in
    end

    # ---------------------------------------------------------------------------

  end

end