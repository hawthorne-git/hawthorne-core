class HawthorneCore::AccountApplicationController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  # verify that the user is signed-in
  before_action :user_signed_in?

  # verify that the signed-in user exists as an active user
  before_action :active_user?

  before_action :set_paper_trail_whodunnit

  # set the request context - the users id, ip, and session token
  before_action :set_request_context

  # ----------------------

  # clear the request context - the users id, ip, and session token
  after_action :clear_request_context

  # ---------------------------------------------------------------------------

  def user_for_paper_trail = session[:user_id]

  def info_for_paper_trail = { whodunnit_type: 'HawthorneCore::User' }

  # ---------------------------------------------------------------------------

end