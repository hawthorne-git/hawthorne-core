# v3.0

class HawthorneCore::UserController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  before_action :validate_signed_in?, only: [
    :show
  ]

  # ----------------------------------------------------------------------------- Show (Account)

  # show the users account
  def show

    # ----------------------


    # ----------------------

    @html_title = 'My Account'

    # ----------------------

  end

  # -----------------------------------------------------------------------------

end