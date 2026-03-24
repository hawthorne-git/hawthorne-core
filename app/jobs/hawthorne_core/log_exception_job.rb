# v3.0XXX

# log an exception
class HawthorneCore::LogExceptionJob < HawthorneCore::ApplicationJob

  queue_as :critical

  def perform(loc, note, exception_class, exception_message)

    HawthorneCore::ActiveRecordBase.with_writing do

      HawthorneCore::SiteException.create!(
        site_id: HawthorneCore::Site.this_site_id,
        location: loc,
        note: note,
        exception_class: exception_class,
        exception_message: exception_message
      )
    end

  end

end