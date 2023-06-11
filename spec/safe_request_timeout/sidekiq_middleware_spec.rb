# frozen_string_literal: true

require_relative "../spec_helper"

describe SafeRequestTimeout::SidekiqMiddleware do
  it "sets up a timeout in the middleware from the safe_request_timeout option" do
    middleware = SafeRequestTimeout::SidekiqMiddleware.new
    job = {"safe_request_timeout" => 5}
    result = middleware.call(Object, job, "default") { SafeRequestTimeout.time_remaining }
    expect(result).to be > 0
  end

  it "does not set a timeout if the safe_request_timeout option is not set" do
    middleware = SafeRequestTimeout::SidekiqMiddleware.new
    job = {}
    result = middleware.call(Object, job, "default") { SafeRequestTimeout.time_remaining }
    expect(result).to eq nil
  end
end
