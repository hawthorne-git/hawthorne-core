# v3.0

module HawthorneCore::Helpers::Bot

  # ----------------------------------------------------------------

  IP_BOTS = %w[
    2a06:98c0:3600::103
  ].freeze

  REFERER_BOTS = %w[
    hawthorne-s3-bucket
  ].freeze

  USER_AGENT_BOTS = %w[
    bingbot
    facebookexternalhit
    claudebot
    cloudflare-ssldetector
    googlebot
    google-site-verification
    gptbot
  ].freeze

  # ----------------------------------------------------------------

  def self.bot?(request:) = referer_bot?(referer: request.env['HTTP_REFERER']) || user_agent_bot?(user_agent: request.env['HTTP_USER_AGENT']) || ip_bot?(ip: request.remote_ip)

  # ----------------------------------------------------------------

  private

  def self.ip_bot?(ip:) = IP_BOTS.include?(ip&.downcase)

  def self.referer_bot?(referer:) = REFERER_BOTS.include?(referer&.downcase)

  def self.user_agent_bot?(user_agent:) = USER_AGENT_BOTS.include?(user_agent&.downcase)

  # ----------------------------------------------------------------

end