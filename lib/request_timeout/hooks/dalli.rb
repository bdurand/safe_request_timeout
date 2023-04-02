# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Dalli < Base
      def initialize
        @klass = ::Dalli::Client if defined?(::Dalli::Client)
        @name = :memcache
        @methods = [:perform]
      end
    end
  end
end
