# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Cassandra < Base
      def initialize
        @klass = ::Cassandra::Session if defined?(::Cassandra::Session)
        @methods = [:execute, :prepare]
      end
    end
  end
end
