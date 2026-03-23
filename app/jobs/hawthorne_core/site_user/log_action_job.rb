# v3.0

# log a site user action
class HawthorneCore::SiteUser::LogActionJob < HawthorneCore::ApplicationJob

  queue_as :low

  def perform(site_user_id, action, success, failure_reason, note, ip_address, site_user_token)

    HawthorneCore::ActiveRecordBase.with_writing do
      HawthorneCore::SiteUserAction.create!(
        site_id: HawthorneCore::Site.this_site_id,
        site_user_id: site_user_id,
        action: action,
        success: success,
        failure_reason: failure_reason,
        note: note.presence,
        ip_address: ip_address,
        site_user_token: site_user_token
      )
    end

  end

end