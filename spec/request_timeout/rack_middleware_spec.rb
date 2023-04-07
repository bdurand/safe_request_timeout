# frozen_string_literal: true

require_relative "../spec_helper"

describe RequestTimeout::RackMiddleware do
  it "sets up a timeout in the middleware" do
    app = lambda do |env|
      [200, {v: env[:v], remaining: RequestTimeout.time_remaining}, ["OK"]]
    end
    middleware = RequestTimeout::RackMiddleware.new(app, 5)
    response = middleware.call({v: 1})
    expect(response[0]).to eq 200
    expect(response[1][:v]).to eq 1
    expect(response[1][:remaining]).to be > 0
    expect(response[2]).to eq ["OK"]
  end

  it "can use a timeout block in the middleware" do
    app = lambda do |env|
      [200, {v: env[:v], remaining: RequestTimeout.time_remaining}, ["OK"]]
    end
    middleware = RequestTimeout::RackMiddleware.new(app, lambda { 5 })
    response = middleware.call({v: 1})
    expect(response[0]).to eq 200
    expect(response[1][:v]).to eq 1
    expect(response[1][:remaining]).to be > 0
    expect(response[2]).to eq ["OK"]
  end

  it "can use a timeout block in the middleware that takes the env as a argument" do
    app = lambda do |env|
      [200, {v: env[:v], remaining: RequestTimeout.time_remaining}, ["OK"]]
    end
    middleware = RequestTimeout::RackMiddleware.new(app, lambda { |env| env[:timeout] })
    response = middleware.call({v: 1, timeout: 5})
    expect(response[0]).to eq 200
    expect(response[1][:v]).to eq 1
    expect(response[1][:remaining]).to be > 0
    expect(response[2]).to eq ["OK"]
  end
end
