# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class NetHTTP < Base
      def initialize
        @klass = ::Net::HTTP if defined?(::Net::HTTP)
        @methods = [:request]
      end
    end
  end
end
