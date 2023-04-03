# frozen_string_literal: true

require "timeout"

# This module adds the capability to add a general timeout to any block of code.
# Unlike the Timeout module, an error is not raised to indicate a timeout.
# Instead, the `timed_out?` method can be used to check if the block of code
# has taken longer than the specified duration so the application can take
# the appropriate action.
#
# This is a safer alternative to the Timeout module because it does not fork new
# threads or risk raising errors from unexpected places.
#
# @example
#   RequestTimeout.timeout(5) do
#     # calling check_timeout! will raise an error if the block has taken
#     # longer than 5 seconds to execute.
#     RequestTimeout.check_timeout!
#   end
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

      previous_start_at = Thread.current[:request_timeout_started_at]
      previous_timeout_at = Thread.current[:request_timeout_timeout_at]

      start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      timeout_at = start_at + duration if duration
      if timeout_at && previous_timeout_at && previous_timeout_at < timeout_at
        timeout_at = previous_timeout_at
      end

      begin
        Thread.current[:request_timeout_started_at] = start_at
        Thread.current[:request_timeout_timeout_at] = timeout_at
        yield
      ensure
        Thread.current[:request_timeout_started_at] = previous_start_at
        Thread.current[:request_timeout_timeout_at] = previous_timeout_at
      end
    end

    # Check if the current timeout block has timed out.
    #
    # @return [Boolean] true if the current timeout block has timed out
    def timed_out?
      timeout_at = Thread.current[:request_timeout_timeout_at]
      !!timeout_at && Process.clock_gettime(Process::CLOCK_MONOTONIC) > timeout_at
    end

    # Raise an error if the current timeout block has timed out. If there is no timeout block,
    # then this method does nothing. If an error is raised, then the current timeout
    # is cleared to prevent the error from being raised multiple times.
    #
    # @return [void]
    # @raise [RequestTimeout::TimeoutError] if the current timeout block has timed out
    def check_timeout!
      if timed_out?
        Thread.current[:request_timeout_timeout_at] = nil
        raise TimeoutError.new("after #{time_elapsed.round(6)} seconds")
      end
    end

    # Get the number of seconds remaining in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds remaining in the current timeout block
    def time_remaining
      timeout_at = Thread.current[:request_timeout_timeout_at]
      [timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.0].max if timeout_at
    end

    # Get the number of seconds elapsed in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds elapsed in the current timeout block began
    def time_elapsed
      start_at = Thread.current[:request_timeout_started_at]
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_at if start_at
    end

    # Set the duration for the current timeout block. This is useful if you want to set the duration
    # after the timeout block has started. The timer for the timeout block will restart whenever
    # a new duration is set.
    #
    # @return [void]
    def set_timeout(duration)
      if Thread.current[:request_timeout_started_at]
        start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = duration.call if duration.respond_to?(:call)
        timeout_at = start_at + duration if duration
        Thread.current[:request_timeout_started_at] = start_at
        Thread.current[:request_timeout_timeout_at] = timeout_at
      end
    end

    # Clear the current timeout. If a block is passed, then the timeout will be cleared
    # only for the duration of the block.
    #
    # @yield the block to execute if one is given
    # @yieldreturn [Object] the result of the block
    def clear_timeout(&block)
      if block
        timeout(nil, &block)
      else
        set_timeout(nil)
      end
    end
  end
end

require_relative "request_timeout/hooks"
require_relative "request_timeout/active_record_hook"
require_relative "request_timeout/rack_middleware"
require_relative "request_timeout/sidekiq_middleware"
require_relative "request_timeout/version"

if defined?(Rails::Railtie)
  require_relative "request_timeout/railtie"
end
