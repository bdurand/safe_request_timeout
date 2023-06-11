# frozen_string_literal: true

require_relative "../spec_helper"

describe SafeRequestTimeout::ActiveRecordHook do
  it "should add the timeout check" do
    SafeRequestTimeout.timeout(0.1) do
      TestModel.count
      sleep 0.11
      expect { TestModel.count }.to raise_error(SafeRequestTimeout::TimeoutError)
    end
  end

  it "should not raise a timeout error after a transaction has committed" do
    SafeRequestTimeout.timeout(0.1) do
      TestModel.create!(name: "test")
      sleep 0.11
      expect { TestModel.count }.to_not raise_error
    end
  end
end
