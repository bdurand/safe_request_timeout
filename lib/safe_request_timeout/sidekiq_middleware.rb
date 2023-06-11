# frozen_string_literal: true

module SafeRequestTimeout
  # Sidekiq server middleware that wraps job execution with a timeout. The timeout
  # is set in a job's "safe_request_timeout" option.
  class SidekiqMiddleware
    if defined?(Sidekiq::ServerMiddleware)
      include Sidekiq::ServerMiddleware
    end

    def call(job_instance, job_payload, queue)
      SafeRequestTimeout.timeout(job_payload["safe_request_timeout"]) do
        yield
      end
    end
  end
end
