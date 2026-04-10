# v3.0

class HawthorneCore::AccountApplicationController < ::HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in prior to all actions
  before_action :verify_signed_in?

  # ---------------------------------------------------------------------------

end