module HawthorneCore
  module Models

    class Order < ActiveRecord::Base

      #include ActiveModel::Model
      #include ActiveModel::Attributes

      def self.charlie
        puts 'here i am charlie boy ...'
        find_by(order_id: 1037193)
      end

    end

  end
end