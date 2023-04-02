# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class Typhoeus < Base
      def initialize
        @klass = ::Typhoeus::Hydra if defined?(::Typhoeus::Hydra)
        @methods = [:run]
      end
    end
  end
end
