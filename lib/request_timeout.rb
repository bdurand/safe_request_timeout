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
    # @param duration [Integer] the number of seconds to wait before timing out
    # @yield the block to execute
    # @yieldreturn [Object] the result of the block
    def timeout(duration, &block)
      duration = duration.call if duration.respond_to?(:call)

      previous_start_at = Thread.current.thread_variable_get(:request_timeout_started_at)
      previous_timeout_at = Thread.current.thread_variable_get(:request_timeout_timeout_at)

      start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      timeout_at = start_at + duration if duration
      if timeout_at && previous_timeout_at && previous_timeout_at < timeout_at
        timeout_at = previous_timeout_at
      end

      begin
        Thread.current.thread_variable_set(:request_timeout_started_at, start_at)
        Thread.current.thread_variable_set(:request_timeout_timeout_at, timeout_at)
        yield
      ensure
        Thread.current.thread_variable_set(:request_timeout_started_at, previous_start_at)
        Thread.current.thread_variable_set(:request_timeout_timeout_at, previous_timeout_at)
      end
    end

    # Check if the current timeout block has timed out.
    #
    # @return [Boolean] true if the current timeout block has timed out
    def timed_out?
      timeout_at = Thread.current.thread_variable_get(:request_timeout_timeout_at)
      !!timeout_at && Process.clock_gettime(Process::CLOCK_MONOTONIC) > timeout_at
    end

    # Check if the current timeout block has timed out and raise an error if it has.
    #
    # @return [void]
    # @raise [RequestTimeout::TimeoutError] if the current timeout block has timed out
    def check_timeout!
      raise TimeoutError.new("after #{time_elapsed.round(3)}ms") if timed_out?
    end

    # Get the number of seconds remaining in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds remaining in the current timeout block
    def time_remaining
      timeout_at = Thread.current.thread_variable_get(:request_timeout_timeout_at)
      [timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.0].max if timeout_at
    end

    # Get the number of seconds elapsed in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds elapsed in the current timeout block began
    def time_elapsed
      start_at = Thread.current.thread_variable_get(:request_timeout_started_at)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_at if start_at
    end

    # Set the duration for the current timeout block. This is useful if you want to set the duration
    # after the timeout block has started. The timer for the timeout block will restart whenever
    # a new duration is set.
    def set_timeout(duration)
      if Thread.current.thread_variable_get(:request_timeout_started_at)
        start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = duration.call if duration.respond_to?(:call)
        timeout_at = start_at + duration if duration
        Thread.current.thread_variable_set(:request_timeout_started_at, start_at)
        Thread.current.thread_variable_set(:request_timeout_timeout_at, timeout_at)
      end
    end
  end
end

require_relative "request_timeout/hooks"
require_relative "request_timeout/rack_middleware"
require_relative "request_timeout/sidekiq_middleware"
require_relative "request_timeout/version"
