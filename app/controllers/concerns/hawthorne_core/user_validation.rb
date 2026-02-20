module HawthorneCore::UserValidation
  extend ActiveSupport::Concern

  included do

    # --------------------------------------------------------------------------- Email Address

    # determine if the email address is already taken
    def email_address_taken?(email_address)
      Core::User.
        where(email_address: email_address).
        where(site_id: Core::Site.this_site_shared_ids).
        exists?
    end

    # -------------------

    # determine if an email address syntax is valid
    def email_address_syntax_valid?(email_address)

      # return false if it does not match its regex
      return false unless email_address =~ URI::MailTo::EMAIL_REGEXP

      # get the domain of the email address - ex: charlieprezzano@gmail.com, domain: gmail.com
      # return false if the domain is blank
      # return false if the domain is included on our internal list, of invalid domains
      email_address_domain = email_address.split('@').last
      return false if email_address_domain.blank?
      return false if Core::InvalidEmailAddressDomain.domain_invalid?(email_address_domain)

      # all validation passed, return true - that it is a valid email address
      true

    end

    # determine if an email address syntax is invalid
    def email_address_syntax_invalid?(email_address)
      !email_address_syntax_valid?(email_address)
    end

    # --------------------------------------------------------------------------- Encryption

    # encrypt the email address
    # this happens when the user deletes their account
    # a lesser cost factor is used as encrypting is not critical
    def encrypt_email_address(email_address)
      BCrypt::Password.create(email_address, cost: 6)
    end

    # encrypt the passcode
    def encrypt_passcode(passcode)
      BCrypt::Password.create(passcode, cost: 14)
    end

    # --------------------------------------------------------------------------- Passcode

    # determine if the passcode matches the encrypted passcode
    def passcode_correct?(encrypted_passcode, passcode)
      BCrypt::Password.new(encrypted_passcode) == passcode
    end

    # determine if the passcode does not match the encrypted passcode
    def passcode_incorrect?(encrypted_passcode, passcode)
      !passcode_correct?(encrypted_passcode, passcode)
    end

    # -------------------

    # determine if the passcode is valid
    # the only check is in it length - it must be 8+ characters in length
    def passcode_valid?(passcode)
      passcode.length >= 8
    end

    # determine if the passcode is invalid
    def passcode_invalid?(passcode)
      !passcode_valid?(passcode)
    end

    # --------------------------------------------------------------------------- Validate: Signed In / Out

    # validates that the user is signed in
    # if not, redirect the user to the sign-in page
    def validate_signed_in
      redirect_to sign_in_path unless @signed_in
    end

    # validates that the user is signed out
    # if not, redirect the user to the sign-out action
    def validate_signed_out
      redirect_to sign_out_path if @signed_in
    end

    # ---------------------------------------------------------------------------

  end

end