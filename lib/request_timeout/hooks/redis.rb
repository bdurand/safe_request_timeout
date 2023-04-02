# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Redis < Base
      def initialize
        if defined?(::RedisClient::ConnectionMixin)
          @klass = ::RedisClient::ConnectionMixin
          @methods = [:call]
        elsif defined?(::Redis::Client)
          @klass = ::Redis::Client
          @methods = [:process]
        end
      end
    end
  end
end
