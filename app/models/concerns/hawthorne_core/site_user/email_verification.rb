# v3.0

module HawthorneCore::SiteUser::EmailVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def email_address_verified? = email_address_verified

    # -----------------------------------------------------------------------------

    # verify a users email address ... if not previously verified
    def verify_email_address
      return if email_address_verified?
      with_writing { update!(email_address_verified: true, email_address_verified_at: Time.current) }
      HawthorneCore::SiteUserAction::Log.email_address_verified(id, { email_address: email_address })
    end

    # -----------------------------------------------------------------------------

  end

end