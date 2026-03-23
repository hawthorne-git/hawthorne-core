# v3.0

class HawthorneCore::SiteUser < HawthorneCore::ActiveRecordBase

  include HawthorneCore::HasPhoneNumber,
          HawthorneCore::HasSmallWebId,
          HawthorneCore::SiteUser::Braintree,
          HawthorneCore::SiteUser::EmailVerification,
          HawthorneCore::SiteUser::PhoneVerification,
          HawthorneCore::SiteUser::PinVerification,
          HawthorneCore::SiteUser::SingleSignOn

  # -----------------------------------------------------------------------------

  self.table_name = 'site_users'

  # -----------------------------------------------------------------------------

  after_create_commit :set_small_web_id

  # -----------------------------------------------------------------------------

  def id = site_user_id

  def token = small_web_id

  # ------------------------

  def first_sign_in? = !email_address_verified?

  # ----------------------------------------------------------------------------- Create Record ???

  # create the site user record, returning its token
  # after the record is created ... log it, create a pin for validation, then email this pin to the user
  def self.create_record(email_address, phone_number, ip_address, site_user_token)
    with_writing do

      # create the site user record ... rescue (and log) if exception caught
      begin
        site_user = create!(email_address: email_address, phone_number: phone_number)
      rescue StandardError => e
        failure_reason = "EXCEPTION CREATING SITE USER RECORD: #{e.class} - #{e.message}"
        HawthorneCore::SiteUserAction::Log.sign_up_failure(failure_reason, { email_address: email_address, phone_number: phone_number }, ip_address, site_user_token)
        HawthorneCore::SiteException.log('CREATE RECORD: SITE_USER', e)
        return nil
      end

      # log the sign-up action
      HawthorneCore::SiteUserAction::Log.sign_up(site_user.id, { email_address: email_address, phone_number: phone_number }, ip_address, site_user_token)

      # create the user a pin, then email it to the users address on file
      site_user.create_pin
      HawthorneCore::Email::SendPinEmailJob.perform_later(site_user.id)

      # return the users id
      site_user.token

    end
  end

  # -----------------------------------------------------------------------------

  # post actions on creating a user record
  # (1) send the user a welcome email
  # (2) create the user in braintree account
  # def self.create_record_post(site_user_id, email_address)
  # HawthorneCore::Email::SendWelcomeEmailJob.perform_later(site_user_id, email_address)
  # CoreJobs::Braintree::CreateUserJob.perform_later(user_id, email_address)
  # end

  # determine if their is an account with this email address
  # TODO: needed????
  def self.account?(email_address)
    exists?(email_address: email_address)
  end

  # -----------------------------------------------------------------------------

end