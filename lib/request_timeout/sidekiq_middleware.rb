# frozen_string_literal: true

module RequestTimeout
  class SidekiqMiddleware
    def call(worker, job, queue)
      RequestTimeout.timeout(job["request_timeout"]) do
        yield
      end
    end
  end
end
