# frozen_string_literal: true

module RequestTimeout
  class RackMiddleware
    def initialize(app, timeout)
      @app = app
      @timeout = timeout
    end

    def call(env)
      RequestTimeout.timeout(@timeout) do
        @app.call(env)
      end
    end
  end
end
