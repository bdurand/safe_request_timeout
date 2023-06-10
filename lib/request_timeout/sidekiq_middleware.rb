# frozen_string_literal: true

module RequestTimeout
  # Sidekiq server middleware that wraps job execution with a timeout. The timeout
  # is set in a job's "request_timeout" option.
  class SidekiqMiddleware
    if defined?(Sidekiq::ServerMiddleware)
      include Sidekiq::ServerMiddleware
    end

    def call(job_instance, job_payload, queue)
      RequestTimeout.timeout(job_payload["request_timeout"]) do
        yield
      end
    end
  end
end
