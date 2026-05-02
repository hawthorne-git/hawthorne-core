# v3.0

module HawthorneCore::User::Code
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    CODE_RANGE = (100_000..999_999).freeze

    CODE_EXPIRATION_IN_MINUTES = 5

    CODE_MAX_FAILED_ATTEMPTS_ALLOWED = 5

    CODE_RECENTLY_SENT_IN_SECONDS = 20

    CODE_VIA_EMAIL = 'EMAIL'.freeze

    CODE_VIA_PHONE = 'PHONE'.freeze

    # -----------------------------------------------------------------------------

  end

end