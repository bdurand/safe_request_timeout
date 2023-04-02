# frozen_string_literal: true

require_relative "../../spec_helper"

describe RequestTimeout::Hooks::Bunny do
  it "should be valid" do
    instance = RequestTimeout::Hooks::Bunny.new
    expect(instance.klass).to_not eq nil
    expect(instance).to be_valid
  end
end
