# v3.0

class HawthorneCore::User::RegistrationController < HawthorneCore::ApplicationController

  # -----------------------------------------------------------------------------

  before_action :validate_signed_out, only: [
    :sign_up_show,
  ]

  # -----------------------------------------------------------------------------

  # show the sign-in page
  def sign_up_show
    @html_title = 'Sign In'
    @meta_description = 'Sign into your ' + HawthorneCore::Site.this_site_name + ' account'
  end

  # -----------------------------------------------------------------------------

end