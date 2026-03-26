# v3.0

module HawthorneCore::User::PinVerification
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    PIN_RANGE = 100_000..999_999.freeze

    PIN_EXPIRATION_IN_MINUTES = 10.freeze

    PIN_MAX_FAILED_ATTEMPTS_ALLOWED = 5.freeze

    PIN_VIA_EMAIL = 'EMAIL'.freeze

    PIN_VIA_PHONE = 'PHONE'.freeze

    # -----------------------------------------------------------------------------

    def pin_default_delivery_via_email? = (pin_default_delivery == PIN_VIA_EMAIL)

    def pin_default_delivery_via_phone? = (pin_default_delivery == PIN_VIA_PHONE)

    # ------------------------

    def pin_active? = pin_set? && !pin_expired? && !pin_max_failed_attempts_reached?

    def pin_expired? = (pin_created_at < PIN_EXPIRATION_IN_MINUTES.minutes.ago)

    def pin_max_failed_attempts_reached? = (pin_failed_attempts_count >= PIN_MAX_FAILED_ATTEMPTS_ALLOWED)

    def pin_set? = pin.present? && pin_created_at.present?

    # ------------------------

    def pin_match?(pin_to_match) = (pin == pin_to_match.gsub(/\D/, '').to_i)

    # -----------------------------------------------------------------------------

    # clear the users pin
    def clear_pin
      update!(pin: nil, pin_created_at: nil, pin_failed_attempts_count: nil)
      HawthorneCore::UserAction::Log.pin_cleared(id)
    end

    # ------------------------

    # refresh the users pin ... only do so if inactive
    def refresh_pin
      unless pin_active?
        update!(pin: SecureRandom.random_number(PIN_RANGE), pin_created_at: Time.current, pin_failed_attempts_count: 0)
        HawthorneCore::UserAction::Log.pin_created(id, { pin: pin })
      end
    end

    # refresh the users pin, then send it via email / phone
    def refresh_pin_then_send_it(delivery_method)
      refresh_pin
      HawthorneCore::Email::SendPinJob.perform_later(id) if (delivery_method == PIN_VIA_EMAIL)
      HawthorneCore::Text::SendPinJob.perform_later(id) if (delivery_method == PIN_VIA_PHONE)
    end

    # ------------------------

    # add a failed pin attempt
    def add_pin_failed_attempt
      update!(pin_failed_attempts_count: (pin_failed_attempts_count.to_i + 1))
    end

    # -----------------------------------------------------------------------------

  end

end