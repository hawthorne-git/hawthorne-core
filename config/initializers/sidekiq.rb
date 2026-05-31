unless Rails.env.development?

  Rails.application.config.active_job.queue_adapter = :sidekiq

  Sidekiq.configure_server do |config|
    config.redis = { url: HawthorneCore::AppConfig.redis_sidekiq_url }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: HawthorneCore::AppConfig.redis_sidekiq_url }
  end

  Sidekiq.strict_args!(false)

end