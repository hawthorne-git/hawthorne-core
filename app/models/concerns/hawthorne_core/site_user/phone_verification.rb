# v3.0

module HawthorneCore::SiteUser::PhoneVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    def phone_number_verified? = phone_number_verified

    # -----------------------------------------------------------------------------

    # verify a users phone number ... if not previously verified
    def verify_phone_number
      return if phone_number_verified?
      with_writing { update!(phone_number_verified: true, phone_number_verified_at: Time.current) }
    end

    # -----------------------------------------------------------------------------

  end

end