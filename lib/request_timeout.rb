# frozen_string_literal: true

require "timeout"

# TODO
module RequestTimeout
  class TimeoutError < ::Timeout::Error
  end

  class << self
    # Execute the given block with a timeout. If the block takes longer than the specified
    # duration to execute, then the `timed_out?`` method will return true within the block.
    #
    # No error will be raised since there is no point in raising an error if the request
    # is already done. It is up to included methods to detect the timeout and raise an
    # error. The included hooks will do just that and raise a `RequestTimeout::TimeoutError`.
    #
    # @param duration [Integer] the number of seconds to wait before timing out
    # @yield the block to execute
    # @yieldreturn [Object] the result of the block
    # @raise [RequestTimeout::TimeoutError] if a hook detects the timeout
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

    # Check if the current timeout block has timed out.
    #
    # @return [Boolean] true if the current timeout block has timed out
    def timed_out?
      timeout_at = Thread.current.thread_variable_get(:request_timeout_at).to_f
      timeout_at > 0.0 && Process.clock_gettime(Process::CLOCK_MONOTONIC) > timeout_at
    end

    # Get the number of seconds remaining in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds remaining in the current timeout block
    def time_remaining
      timeout_at = Thread.current.thread_variable_get(:request_timeout_at).to_f
      [timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.0].max if timeout_at > 0.0
    end

    # Set the duration for the current timeout block. This is useful if you want to set the duration
    # after the timeout block has started. The timer for the timeout block will restart whenever
    # a new duration is set.
    def set_timeout(duration)
      if Thread.current.thread_variable_get(:request_timeout_at)
        Thread.current.thread_variable_set(:request_timeout_at, timeout_at_time(duration))
      end
    end

    private

    def timeout_at_time(duration)
      duration = duration.call if duration.respond_to?(:call)
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
