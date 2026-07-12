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
#   SafeRequestTimeout.timeout(5) do
#     # calling check_timeout! will raise an error if the block has taken
#     # longer than 5 seconds to execute.
#     SafeRequestTimeout.check_timeout!
#   end
module SafeRequestTimeout
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

      state = current_state
      previous_start_at = state[:safe_request_timeout_started_at]
      previous_timeout_at = state[:safe_request_timeout_timeout_at]

      start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      timeout_at = start_at + duration if duration
      if timeout_at && previous_timeout_at && previous_timeout_at < timeout_at
        timeout_at = previous_timeout_at
      end

      begin
        state[:safe_request_timeout_started_at] = start_at
        state[:safe_request_timeout_timeout_at] = timeout_at
        yield
      ensure
        # If the deadline shared with the parent block was already raised by check_timeout!,
        # don't re-arm it when restoring the parent block's state.
        if previous_timeout_at && previous_timeout_at == state[:safe_request_timeout_fired_at]
          previous_timeout_at = nil
        end
        state[:safe_request_timeout_started_at] = previous_start_at
        state[:safe_request_timeout_timeout_at] = previous_timeout_at
        state[:safe_request_timeout_fired_at] = nil if previous_start_at.nil?
      end
    end

    # Check if the current timeout block has timed out.
    #
    # @return [Boolean] true if the current timeout block has timed out
    def timed_out?
      timeout_at = current_state[:safe_request_timeout_timeout_at]
      !!timeout_at && Process.clock_gettime(Process::CLOCK_MONOTONIC) > timeout_at
    end

    # Raise an error if the current timeout block has timed out. If there is no timeout block,
    # then this method does nothing. If an error is raised, then the current timeout
    # is cleared to prevent the error from being raised multiple times.
    #
    # @return [void]
    # @raise [SafeRequestTimeout::TimeoutError] if the current timeout block has timed out
    def check_timeout!
      if timed_out?
        state = current_state
        state[:safe_request_timeout_fired_at] = state[:safe_request_timeout_timeout_at]
        state[:safe_request_timeout_timeout_at] = nil
        raise TimeoutError.new("after #{time_elapsed.round(6)} seconds")
      end
    end

    # Get the number of seconds remaining in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds remaining in the current timeout block
    def time_remaining
      timeout_at = current_state[:safe_request_timeout_timeout_at]
      [timeout_at - Process.clock_gettime(Process::CLOCK_MONOTONIC), 0.0].max if timeout_at
    end

    # Get the number of seconds elapsed in the current timeout block or nil if there is no
    # timeout block.
    #
    # @return [Float, nil] the number of seconds elapsed in the current timeout block began
    def time_elapsed
      start_at = current_state[:safe_request_timeout_started_at]
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_at if start_at
    end

    # Set the duration for the current timeout block. This is useful if you want to set the duration
    # after the timeout block has started. The timer for the timeout block will restart whenever
    # a new duration is set.
    #
    # @return [void]
    def set_timeout(duration)
      state = current_state
      if state[:safe_request_timeout_started_at]
        start_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = duration.call if duration.respond_to?(:call)
        timeout_at = start_at + duration if duration
        state[:safe_request_timeout_started_at] = start_at
        state[:safe_request_timeout_timeout_at] = timeout_at
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

    private

    # Storage for the timeout state. ActiveSupport::IsolatedExecutionState is used when it
    # is available so that the state follows the application's configured isolation level
    # (:thread or :fiber). Otherwise the state is fiber local.
    def current_state
      if defined?(::ActiveSupport::IsolatedExecutionState)
        ::ActiveSupport::IsolatedExecutionState
      else
        ::Thread.current
      end
    end
  end
end

require_relative "safe_request_timeout/hooks"
require_relative "safe_request_timeout/active_record_hook"
require_relative "safe_request_timeout/rack_middleware"
require_relative "safe_request_timeout/sidekiq_middleware"
require_relative "safe_request_timeout/version"

if defined?(Rails::Railtie)
  require_relative "safe_request_timeout/railtie"
end
