# frozen_string_literal: true

require_relative "spec_helper"

describe RequestTimeout do
  describe "timeout" do
    it "can detect a timeout within a block" do
      RequestTimeout.timeout(0.1) do
        expect(RequestTimeout.timed_out?).to eq false
        sleep 0.11
        expect(RequestTimeout.timed_out?).to eq true
      end

      expect(RequestTimeout.timed_out?).to eq false
      expect(RequestTimeout.time_remaining).to be nil
    end

    it "returns the value of the block" do
      expect(RequestTimeout.timeout(1) { :foo }).to eq :foo
    end

    it "does not timeout if the timeout duration is zero" do
      RequestTimeout.timeout(0) do
        expect(RequestTimeout.timed_out?).to eq false
      end
    end

    it "does not timeout if the timeout duration is nil" do
      RequestTimeout.timeout(nil) do
        expect(RequestTimeout.timed_out?).to eq false
      end
    end

    it "can nest timeouts" do
      RequestTimeout.timeout(3) do
        expect(RequestTimeout.time_remaining).to be > 2
        expect(RequestTimeout.time_remaining).to be <= 3

        RequestTimeout.timeout(2) do
          expect(RequestTimeout.time_remaining).to be > 1
          expect(RequestTimeout.time_remaining).to be <= 2
        end

        expect(RequestTimeout.time_remaining).to be > 2
        expect(RequestTimeout.time_remaining).to be <= 3

        RequestTimeout.timeout(4) do
          expect(RequestTimeout.time_remaining).to be > 2
          expect(RequestTimeout.time_remaining).to be <= 3
        end
      end
    end

    it "can set the duration with a Proc" do
      RequestTimeout.timeout(lambda { 1 }) do
        expect(RequestTimeout.time_remaining).to be > 0
        expect(RequestTimeout.time_remaining).to be <= 1
      end
    end
  end

  describe "set_timeout" do
    it "sets a new timeout" do
      RequestTimeout.timeout(1) do
        RequestTimeout.set_timeout(3)
        expect(RequestTimeout.time_remaining).to be > 2

        RequestTimeout.set_timeout(2)
        expect(RequestTimeout.time_remaining).to be > 1

        RequestTimeout.set_timeout(4)
        expect(RequestTimeout.time_remaining).to be > 3

        RequestTimeout.set_timeout(nil)
        expect(RequestTimeout.time_remaining).to be nil

        RequestTimeout.set_timeout(lambda { 2 })
        expect(RequestTimeout.time_remaining).to be > 1
      end
    end

    it "does nothing if not in a timeout block" do
      RequestTimeout.set_timeout(3)
      expect(RequestTimeout.time_remaining).to be nil
    end
  end

  describe "time_remaining" do
    it "returns the time remaining" do
      RequestTimeout.timeout(1) do
        expect(RequestTimeout.time_remaining).to be > 0
      end
    end

    it "returns nil if no timeout is set" do
      expect(RequestTimeout.time_remaining).to eq nil
    end
  end

  describe "VERSION" do
    it "is set" do
      expect(RequestTimeout::VERSION).to_not eq nil
    end
  end
end
