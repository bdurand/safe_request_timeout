# frozen_string_literal: true

require "timeout"

module RequestTimeout
  class TimeoutError < ::Timeout::Error
  end

  class << self
    # @param duration [Integer] the number of seconds to wait before timing out
    # @yield the block to execute
    # @raise [RequestTimeout::TimeoutError] if the block takes longer than `duration` seconds to execute
    def timeout(duration, &block)
      previous_timeout_at = Thread.current.thread_variable_get(:request_timeout_at)
      timeout_at = timeout_at_time(duration)
      if previous_timeout_at.to_f > 0 && timeout_at.to_f > 0 && previous_timeout_at < timeout_at
        timeout_at = previous_timeout_at
      end

      begin
        Thread.current.thread_variable_set(:request_timeout_at, timeout_at)
        yield
      ensure
        Thread.current.thread_variable_set(:request_timeout_at, previous_timeout_at)
      end
    end

    # @return [Boolean] true if the current timeout block has timed out
    def timed_out?
      timeout_at = Thread.current.thread_variable_get(:request_timeout_at).to_f
      timeout_at > 0.0 && Process.clock_gettime(Process::CLOCK_MONOTONIC) > timeout_at
    end

    def time_remaining
      timeout_at = Thread.current.thread_variable_get(:request_timeout_at).to_f
      [timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.0].max if timeout_at > 0.0
    end

    def set_timeout(duration)
      if Thread.current.thread_variable_get(:request_timeout_at)
        Thread.current.thread_variable_set(:request_timeout_at, timeout_at_time(duration))
      end
    end

    private

    def timeout_at_time(duration)
      duration = duration.to_f
      if duration > 0
        Process.clock_gettime(Process::CLOCK_MONOTONIC) + duration
      else
        0
      end
    end
  end
end

require_relative "request_timeout/hooks"
require_relative "request_timeout/rack_middleware"
require_relative "request_timeout/sidekiq_middleware"
require_relative "request_timeout/version"
