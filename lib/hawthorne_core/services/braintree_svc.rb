# v3.0XXX

# Braintree services
class HawthorneCore::Services::BraintreeSvc

  # ---------------------------------------------------------------- User

  # create the user within the braintree vault
  # set the braintree customer id to the user
  # https://developer.paypal.com/braintree/docs/reference/request/customer/create/ruby
  def self.create_user(site_user_id)

    # find the user by id
    site_user = HawthorneCore::User.
      select(:site_user_id, :braintree_id, :email_address).
      find_by(site_user_id: site_user_id)

    # in the unexpected case where the user is not found, return
    unless site_user
      HawthorneCore::UserAction::Log.braintree_customer_id_attached_failure(nil, HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Site User not found with id', site_user_id: site_user_id })
      return
    end

    # in the unexpected case where the user already has a braintree account attached, return
    if site_user.braintree_account?
      HawthorneCore::UserAction::Log.braintree_customer_id_attached_failure(site_user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { message: 'Braintree account already attached', site_user_id: site_user_id, braintree_id: site_user.braintree_id })
      return
    end

    # generate a braintree customer id (token)
    braintree_id = generate_customer_token

    # create the customer within braintree
    begin
      result = client.customer.create(id: braintree_id, email: site_user.email_address)
    rescue StandardError => e
      HawthorneCore::UserAction::Log.braintree_customer_id_attached_failure(site_user.id, HawthorneCore::UserAction::FailureReason.exception_caught, { braintree_id: braintree_id, email_address: site_user.email_address, exception_class: e.class, exception_message: e.message })
      HawthorneCore::SiteException.log('HawthorneCore::Services::BraintreeSvc.create_user', { braintree_id: braintree_id, email_address: site_user.email_address }, e)
      return
    end

    # in the unexpected case there was an error creating the customer within braintree
    unless result.success?
      errors = result.errors.map { |e| { code: e.code, message: e.message } }
      errors.each do |error|
        HawthorneCore::UserAction::Log.braintree_customer_id_attached_failure(site_user.id, HawthorneCore::UserAction::FailureReason.unexpected_state, { braintree_id: braintree_id, email_address: site_user.email_address, error: error })
      end
      return
    end

    # the result is a success ...
    # attach the braintree customer id to the user
    site_user.attach_braintree_customer_id(braintree_id)

  end

  # ----------------------------------------------------------------

  private

  # ------------------------

  ENVIRONMENTS = {
    'PRODUCTION' => :production,
    'SANDBOX' => :sandbox
  }.freeze

  # ------------------------

  # create the braintree gateway client (once)
  def self.client
    @client ||= Braintree::Gateway.new(
      environment: ENVIRONMENTS.fetch(HawthorneCore::AppConfig.braintree_environment),
      merchant_id: HawthorneCore::AppConfig.braintree_merchant_id,
      public_key: HawthorneCore::AppConfig.braintree_public_key,
      private_key: HawthorneCore::AppConfig.braintree_private_key
    )
  end

  # ------------------------

  def self.generate_credit_card_token = SecureRandom.alphanumeric(36).upcase

  # generate a unique braintree customer token
  def self.generate_customer_token
    loop do
      candidate = SecureRandom.alphanumeric(36).upcase
      return candidate unless HawthorneCore::User.exists?(braintree_id: candidate)
    end
  end

  # ----------------------------------------------------------------

end