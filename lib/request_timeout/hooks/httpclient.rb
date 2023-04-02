# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class HTTPClient < Base
      def initialize
        @klass = ::HTTPClient if defined?(::HTTPClient)
        @methods = [:do_get_block]
      end
    end
  end
end
