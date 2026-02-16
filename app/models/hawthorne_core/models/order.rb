module HawthorneCore
  module Models

    class Order < ActiveRecord::Base

      self.table_name = "orders"

      #include ActiveModel::Model
      #include ActiveModel::Attributes

      def self.charlie
        puts 'here i am charlie boy 12 ...'
        find_by(order_id: 1037193)
      end

    end

  end
end