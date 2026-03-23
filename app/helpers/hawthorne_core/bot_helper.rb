# v3.0

module HawthorneCore::BotHelper

  # ----------------------------------------------------------------

  IP_ADDRESS_BOTS = %w[2a06:98c0:3600::103].freeze

  REFERER_BOTS = %w[hawthorne-s3-bucket].freeze

  USER_AGENT_BOTS = %w[bingbot facebookexternalhit claudebot cloudflare-ssldetector googlebot google-site-verification gptbot].freeze

  # ----------------------------------------------------------------

  # determine if the http request is a bot from the referer, site_user agent, and ip address
  def self.bot?(request)
    referer_bot?(request.env['HTTP_REFERER']) || user_agent_bot?(request.env['HTTP_USER_AGENT']) || ip_address_bot?(request.env['HTTP_CF_CONNECTING_IP'])
  end

  # ----------------------------------------------------------------

  private

  # determine if the http request is a bot, from the ip address
  def self.ip_address_bot?(ip_address)
    IP_ADDRESS_BOTS.include?(ip_address&.downcase)
  end

  # ------------------

  # determine if the http request is a bot, from the referer
  def self.referer_bot?(referer)
    REFERER_BOTS.include?(referer&.downcase)
  end

  # ------------------

  # determine if the http request is a bot, from the site_user agent
  def self.user_agent_bot?(user_agent)
    USER_AGENT_BOTS.include?(user_agent&.downcase)
  end

  # ----------------------------------------------------------------

end