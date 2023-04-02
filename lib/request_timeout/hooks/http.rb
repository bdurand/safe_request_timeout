# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class HTTP < Base
      def initialize
        @klass = ::HTTP::Client if defined?(::HTTP::Client)
        @name = :http
        @methods = [:perform]
      end
    end
  end
end
