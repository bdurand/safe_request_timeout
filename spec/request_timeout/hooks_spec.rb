# frozen_string_literal: true

require_relative "../spec_helper"

class TestHooks
  def thing_1(arg)
    arg
  end

  def thing_2(arg:)
    arg
  end

  def thing_3(arg_1, arg_2:, &block)
    yield(arg_1, arg_2)
  end

  def thing_4(arg)
    arg
  end
end

describe RequestTimeout::Hooks do
  describe "add_timeout!" do
    it "should inject timeout checks into specified methods" do
      object = TestHooks.new
      RequestTimeout::Hooks.add_timeout!(TestHooks, [:thing_1, :thing_2, :thing_3])

      expect(object.thing_1(1)).to eq 1
      expect(object.thing_2(arg: 2)).to eq 2
      expect(object.thing_3(1, arg_2: 2) { |x, y| x + y }).to eq 3

      RequestTimeout.timeout(0.1) do
        expect(object.thing_1(1)).to eq 1
        expect(object.thing_2(arg: 2)).to eq 2
        expect(object.thing_3(1, arg_2: 2) { |x, y| x + y }).to eq 3
        expect(object.thing_4(4)).to eq 4

        sleep 0.11

        expect(object.thing_4(4)).to eq 4
        expect { object.thing_1(1) }.to raise_error(RequestTimeout::TimeoutError)
      end
    end
  end

  describe "auto_setup!" do
    it "should not raise any errors" do
      expect { RequestTimeout::Hooks.auto_setup! }.to_not raise_error
    end
  end
end
