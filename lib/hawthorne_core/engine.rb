# frozen_string_literal: true

require "rails/engine"

module HawthorneCore
  class Engine < ::Rails::Engine
    isolate_namespace HawthorneCore
  end
end