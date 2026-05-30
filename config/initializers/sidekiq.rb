unless Rails.env.development?

  Rails.application.config.active_job.queue_adapter = :sidekiq

  Sidekiq.configure_server do |config|
    config.redis = { url: HawthorneCore::AppConfig.redis_sidekiq_url }
    config.on(:startup) do
      schedule = YAML.load_file(Rails.root.join('config/sidekiq_cron.yml'))
      Sidekiq::Cron::Job.load_from_hash(schedule)
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: HawthorneCore::AppConfig.redis_sidekiq_url }
  end

  Sidekiq.strict_args!(false)

end