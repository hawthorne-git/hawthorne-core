# v3.0

module HawthorneCore::Validation::Address
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------

    # redirect to view all addresses when the address is not found
    def redirect_when_address_not_found(method:, token:)
      HawthorneCore::UserAction::Log.address_failure(failure_reason: HawthorneCore::UserAction::FailureReason.unexpected_state, note: { class: 'HawthorneCore::User::AddressesController', method:, message: 'Users address not found', token: })
      redirect_to account_addresses_path
    end

    # ---------------------------------------------------------------------------

    # render an error message that the address is identical to another on file
    def render_identical_address_error(action:, attrs:)
      HawthorneCore::UserAction::Log.address_failure(failure_reason: HawthorneCore::UserAction::FailureReason.address_identical, note: { action:, attrs: })
      render turbo_stream: turbo_stream.update('form_errors', partial: '/hawthorne_core/user/address_failed', locals: { address_identical: true })
    end

    # ---------------------------------------------------------------------------

  end

end