# frozen_string_literal: true

module RequestTimeout
  # Sidekiq server middleware that wraps job execution with a timeout. The timeout
  # is set in a job's "request_timeout" option.
  class SidekiqMiddleware
    def call(worker, job, queue)
      RequestTimeout.timeout(job["request_timeout"]) do
        yield
      end
    end
  end
end
