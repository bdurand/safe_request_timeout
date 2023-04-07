# frozen_string_literal: true

module RequestTimeout
  # Rack middleware that adds a timeout block to all requests.
  class RackMiddleware
    # @param app [Object] The Rack application to wrap.
    # @param timeout [Integer, Proc, nil] The timeout in seconds.
    def initialize(app, timeout = nil)
      @app = app
      @timeout = timeout
      @timeout_block = true if timeout.is_a?(Proc) && timeout.arity == 1
    end

    def call(env)
      RequestTimeout.timeout(@timeout_block ? @timeout.call(env) : @timeout) do
        @app.call(env)
      end
    end
  end
end
