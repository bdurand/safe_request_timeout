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

  it "should be safe to add the hooks multiple times" do
    expect { SafeRequestTimeout::ActiveRecordHook.add_timeout! }.to_not raise_error

    adapter_class = ActiveRecord::Base.connection_pool.with_connection { |connection| connection.class }
    expect { SafeRequestTimeout::ActiveRecordHook.add_timeout!(adapter_class) }.to_not raise_error
    expect(adapter_class.ancestors.count { |mod| mod.name.to_s.end_with?("AddTimeout") }).to eq 1

    SafeRequestTimeout.timeout(0.1) do
      sleep 0.11
      expect { TestModel.count }.to raise_error(SafeRequestTimeout::TimeoutError)
    end
  end
end
