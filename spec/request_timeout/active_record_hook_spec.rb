# frozen_string_literal: true

require_relative "../spec_helper"

describe RequestTimeout::ActiveRecordHook do
  it "should add the timeout check" do
    RequestTimeout.timeout(0.1) do
      TestModel.count
      sleep 0.11
      expect { TestModel.count }.to raise_error(RequestTimeout::TimeoutError)
    end
  end

  it "should not raise a timeout error after a transaction has committed" do
    RequestTimeout.timeout(0.1) do
      TestModel.create!(name: "test")
      sleep 0.11
      expect { TestModel.count }.to_not raise_error
    end
  end
end
