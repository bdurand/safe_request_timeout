# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Excon < Base
      def initialize
        @klass = ::Excon::Connection if defined?(::Excon::Connection)
        @methods = [:request]
      end
    end
  end
end
