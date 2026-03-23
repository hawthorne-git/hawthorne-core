# v3.0

module HawthorneCore::SiteUser::PinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    PIN_RANGE = 100_000..999_999.freeze

    PIN_EXPIRATION_IN_MINUTES = 10.freeze

    MAX_NBR_ALLOWED_FAILED_PIN_ATTEMPTS = 5.freeze

    PIN_VIA_EMAIL = 'EMAIL'.freeze

    PIN_VIA_PHONE = 'PHONE'.freeze

    PIN_DELIVERY_METHODS = [PIN_VIA_EMAIL, PIN_VIA_PHONE].freeze

    # -----------------------------------------------------------------------------

    def pin_default_delivery_via_email? = email_address_verified? && (!phone_number_verified? || pin_default_delivery == PIN_VIA_EMAIL)

    def pin_default_delivery_via_phone? = email_address_verified? && phone_number_verified? && (pin_default_delivery == PIN_VIA_PHONE)

    def no_pin_default_delivery? = !pin_default_delivery_via_email? && !pin_default_delivery_via_phone?

    # ------------------------

    def pin_active? = pin.present? && pin_created_at.present? && (pin_created_at >= PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def pin_inactive? = !pin_active?

    def pin_match?(pin_to_match) = (pin == pin_to_match.gsub(/\D/, '').to_i)

    def reached_max_allowed_pin_attempts? = nbr_failed_pin_attempts >= MAX_NBR_ALLOWED_FAILED_PIN_ATTEMPTS

    # -----------------------------------------------------------------------------

    # clear the users pin
    def clear_pin
      with_writing { update!(pin: nil, pin_created_at: nil, nbr_failed_pin_attempts: nil) }
      HawthorneCore::SiteUserAction::Log.pin_cleared(id)
    end

    # ------------------------

    # refresh the users pin ... only do so if inactive or reached the max allowed attempts
    def refresh_pin
      if pin_inactive? or reached_max_allowed_pin_attempts?
        with_writing { update!(pin: SecureRandom.random_number(PIN_RANGE), pin_created_at: Time.current, nbr_failed_pin_attempts: 0) }
        HawthorneCore::SiteUserAction::Log.pin_created(id, { pin: pin })
      end
    end

    # refresh the users pin, then send it via email / phone
    def refresh_pin_then_send_it(delivery_method)
      refresh_pin
      case delivery_method
      when PIN_VIA_EMAIL then HawthorneCore::Email::SendPinJob.perform_later(id)
      when PIN_VIA_PHONE then HawthorneCore::Text::SendPinJob.perform_later(id)
      else
        HawthorneCore::SiteException.log('HawthorneCore::SiteUser::PinVerification.refresh_pin_then_send_it', { message: 'unexpected delivery_method value', delivery_method: delivery_method, site_user_id: id }, nil)
        HawthorneCore::Email::SendPinJob.perform_later(id)
      end
    end

    # ------------------------

    # add a failed pin attempt
    def add_failed_pin_attempt
      with_writing { update!(nbr_failed_pin_attempts: (nbr_failed_pin_attempts.to_i + 1)) }
    end

    # -----------------------------------------------------------------------------

  end

end