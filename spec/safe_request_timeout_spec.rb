# frozen_string_literal: true

require "spec_helper"

RSpec.describe SafeRequestTimeout do
  describe "timeout" do
    it "can detect a timeout within a block" do
      SafeRequestTimeout.timeout(0.1) do
        expect(SafeRequestTimeout.timed_out?).to eq false
        sleep 0.11
        expect(SafeRequestTimeout.timed_out?).to eq true
      end

      expect(SafeRequestTimeout.timed_out?).to eq false
      expect(SafeRequestTimeout.time_remaining).to be nil
      expect(SafeRequestTimeout.time_elapsed).to be nil
    end

    it "returns the value of the block" do
      expect(SafeRequestTimeout.timeout(1) { :foo }).to eq :foo
    end

    it "does not timeout if the timeout duration is nil" do
      SafeRequestTimeout.timeout(nil) do
        expect(SafeRequestTimeout.timed_out?).to eq false
      end
    end

    it "can nest timeouts" do
      SafeRequestTimeout.timeout(3) do
        expect(SafeRequestTimeout.time_remaining).to be > 2
        expect(SafeRequestTimeout.time_remaining).to be <= 3
        expect(SafeRequestTimeout.time_elapsed).to be < 0.1

        sleep(0.1)

        SafeRequestTimeout.timeout(2) do
          expect(SafeRequestTimeout.time_remaining).to be > 1
          expect(SafeRequestTimeout.time_remaining).to be <= 2
          expect(SafeRequestTimeout.time_elapsed).to be < 0.1
        end

        expect(SafeRequestTimeout.time_remaining).to be > 2
        expect(SafeRequestTimeout.time_remaining).to be <= 3
        expect(SafeRequestTimeout.time_elapsed).to be > 0.1

        SafeRequestTimeout.timeout(4) do
          expect(SafeRequestTimeout.time_remaining).to be > 2
          expect(SafeRequestTimeout.time_remaining).to be <= 3
        end
      end
    end

    it "can set the duration with a Proc" do
      SafeRequestTimeout.timeout(lambda { 1 }) do
        expect(SafeRequestTimeout.time_remaining).to be > 0
        expect(SafeRequestTimeout.time_remaining).to be <= 1
      end
    end
  end

  describe "check_timeout!" do
    it "raises a single SafeRequestTimeout::TimeoutError if the timeout has been reached" do
      SafeRequestTimeout.timeout(0.1) do
        SafeRequestTimeout.check_timeout!
        sleep 0.11
        expect { SafeRequestTimeout.check_timeout! }.to raise_error(SafeRequestTimeout::TimeoutError)
        SafeRequestTimeout.check_timeout!
      end
    end

    it "does nothing outside of a timeout block" do
      expect { SafeRequestTimeout.check_timeout! }.not_to raise_error
    end

    it "does not raise again in an outer block after a shared deadline has already raised" do
      SafeRequestTimeout.timeout(0.1) do
        begin
          SafeRequestTimeout.timeout(5) do
            sleep 0.11
            SafeRequestTimeout.check_timeout!
          end
        rescue SafeRequestTimeout::TimeoutError
        end

        expect(SafeRequestTimeout.timed_out?).to eq false
        expect { SafeRequestTimeout.check_timeout! }.not_to raise_error
      end
    end

    it "keeps an outer deadline armed when a different inner deadline raises" do
      SafeRequestTimeout.timeout(10) do
        begin
          SafeRequestTimeout.timeout(0.1) do
            sleep 0.11
            SafeRequestTimeout.check_timeout!
          end
        rescue SafeRequestTimeout::TimeoutError
        end

        expect(SafeRequestTimeout.timed_out?).to eq false
        expect(SafeRequestTimeout.time_remaining).to be > 0
      end
    end
  end

  describe "set_timeout" do
    it "sets a new timeout" do
      SafeRequestTimeout.timeout(1) do
        SafeRequestTimeout.set_timeout(3)
        expect(SafeRequestTimeout.time_remaining).to be > 2

        SafeRequestTimeout.set_timeout(2)
        expect(SafeRequestTimeout.time_remaining).to be > 1

        SafeRequestTimeout.set_timeout(4)
        expect(SafeRequestTimeout.time_remaining).to be > 3

        SafeRequestTimeout.set_timeout(nil)
        expect(SafeRequestTimeout.time_remaining).to be nil

        SafeRequestTimeout.set_timeout(lambda { 2 })
        expect(SafeRequestTimeout.time_remaining).to be > 1
      end
    end

    it "does nothing if not in a timeout block" do
      SafeRequestTimeout.set_timeout(3)
      expect(SafeRequestTimeout.time_remaining).to be nil
    end

    it "clears the record of a fired deadline when a new timeout is set" do
      state = (defined?(ActiveSupport::IsolatedExecutionState) ? ActiveSupport::IsolatedExecutionState : Thread.current)
      SafeRequestTimeout.timeout(0.1) do
        sleep 0.11
        begin
          SafeRequestTimeout.check_timeout!
        rescue SafeRequestTimeout::TimeoutError
        end
        expect(state[:safe_request_timeout_fired_at]).to_not be nil

        SafeRequestTimeout.set_timeout(5)
        expect(state[:safe_request_timeout_fired_at]).to be nil
        expect(SafeRequestTimeout.time_remaining).to be > 4
      end
    end
  end

  describe "clear_timeout" do
    it "clears the timeout" do
      SafeRequestTimeout.timeout(1) do
        SafeRequestTimeout.clear_timeout
        expect(SafeRequestTimeout.time_remaining).to be nil
      end
    end

    it "clears the timeout just inside a block" do
      block_called = false
      SafeRequestTimeout.timeout(1) do
        SafeRequestTimeout.clear_timeout do
          block_called = true
          expect(SafeRequestTimeout.time_remaining).to be nil
        end
        expect(SafeRequestTimeout.time_remaining).to be > 0
      end
      expect(block_called).to eq true
    end

    it "does nothing if not in a timeout block" do
      SafeRequestTimeout.clear_timeout
      expect(SafeRequestTimeout.time_remaining).to be nil
    end
  end

  describe "time_remaining" do
    it "returns the time remaining" do
      SafeRequestTimeout.timeout(1) do
        expect(SafeRequestTimeout.time_remaining).to be > 0
      end
    end

    it "returns nil if no timeout is set" do
      expect(SafeRequestTimeout.time_remaining).to eq nil
    end
  end

  describe "time_elapsed" do
    it "returns the time elapsed" do
      SafeRequestTimeout.timeout(1) do
        expect(SafeRequestTimeout.time_elapsed).to be > 0
      end
    end

    it "returns nil if no timeout is set" do
      expect(SafeRequestTimeout.time_elapsed).to eq nil
    end
  end

  describe "state storage" do
    if defined?(ActiveSupport::IsolatedExecutionState)
      it "stores the state in ActiveSupport::IsolatedExecutionState when it is available" do
        SafeRequestTimeout.timeout(1) do
          expect(ActiveSupport::IsolatedExecutionState[:safe_request_timeout_started_at]).to_not be nil
          expect(Thread.current[:safe_request_timeout_started_at]).to be nil
        end
      end
    end

    it "stores the state in Thread.current when ActiveSupport::IsolatedExecutionState is not available" do
      hide_const("ActiveSupport::IsolatedExecutionState") if defined?(ActiveSupport::IsolatedExecutionState)
      SafeRequestTimeout.timeout(1) do
        expect(Thread.current[:safe_request_timeout_started_at]).to_not be nil
        expect(SafeRequestTimeout.time_remaining).to be > 0
      end
    end
  end

  describe "VERSION" do
    it "is set" do
      expect(SafeRequestTimeout::VERSION).to_not eq nil
    end
  end
end
