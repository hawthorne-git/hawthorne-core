# v3.0

class HawthorneCore::AccountApplicationController < ::HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in
  before_action :user_signed_in?

  # verify that the signed-in user exists as an active user
  before_action :active_user?

  # set the request context - the users id, ip address and session token
  before_action :set_request_context

  # ----------------------

  # clear the request context - the users id, ip address and session token
  after_action :clear_request_context

  # ---------------------------------------------------------------------------

end