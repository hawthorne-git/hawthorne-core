# v3.0XXX

# log a user action
class HawthorneCore::User::LogActionJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(user_id, action, success, failure_reason, note, ip_address, user_session_token)
    HawthorneCore::UserAction.create_record(
      user_id: user_id,
      action: action,
      success: success,
      failure_reason: failure_reason,
      note: note.presence,
      ip_address: ip_address,
      user_session_token: user_session_token
    )
  end

end