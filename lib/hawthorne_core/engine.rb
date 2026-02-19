# frozen_string_literal: true

require 'rails/engine'

module HawthorneCore

  class Engine < ::Rails::Engine

    isolate_namespace HawthorneCore

    # validate that required hawthorne core env variables exist
    initializer 'hawthorne_core.validate_env' do
      HawthorneCore::AppConfig.site_name
    end

  end

end