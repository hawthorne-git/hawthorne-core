module HawthorneCore

  class ApplicationController < ActionController::Base

    include HawthorneCore::Cache

    helper HawthorneCore::AwsHelper,
           HawthorneCore::CalcHelper,
           HawthorneCore::DateHelper,
           HawthorneCore::ImageHelper,
           HawthorneCore::ImageTypeHelper,
           HawthorneCore::LinkHelper,
           HawthorneCore::ProductHelper

  end

end