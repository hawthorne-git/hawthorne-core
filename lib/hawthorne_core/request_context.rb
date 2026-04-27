# v3.0

module HawthorneCore
  module RequestContext
    extend self

    def set(user_id:, ip:, user_session_token:)
      Thread.current[:hawthorne_request_context] = { user_id:, ip: ip, user_session_token: user_session_token }
    end

    def get
      Thread.current[:hawthorne_request_context] || {}
    end

    def clear
      Thread.current[:hawthorne_request_context] = nil
    end

  end
end