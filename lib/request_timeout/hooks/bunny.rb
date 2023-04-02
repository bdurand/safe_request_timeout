# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Bunny < Base
      def initialize
        @klass = ::Bunny::Channel if defined?(::Bunny::Channel)
        @name = :rabbitmq
        @methods = [
          :basic_get,
          :basic_publish,
          :basic_ack,
          :basic_nack,
          :basic_consume,
          :basic_consume_with,
          :basic_recover,
          :basic_cancel,
          :basic_qos,
          :basic_reject
        ]
      end
    end
  end
end
