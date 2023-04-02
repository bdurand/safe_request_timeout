# frozen_string_literal: true

require_relative "../spec_helper"

describe RequestTimeout::SidekiqMiddleware do
  it "sets up a timeout in the middleware from the request_timeout option" do
    middleware = RequestTimeout::SidekiqMiddleware.new
    job = {"request_timeout" => 5}
    result = middleware.call(Object, job, "default") { RequestTimeout.time_remaining }
    expect(result).to be > 0
  end

  it "does not set a timeout if the request_timeout option is not set" do
    middleware = RequestTimeout::SidekiqMiddleware.new
    job = {}
    result = middleware.call(Object, job, "default") { RequestTimeout.time_remaining }
    expect(result).to eq nil
  end
end
