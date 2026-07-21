# frozen_string_literal: true

require "spec_helper"

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

class TestHooksDuplicate
  def thing(arg)
    arg
  end
end

RSpec.describe SafeRequestTimeout::Hooks do
  describe "add_timeout!" do
    it "does not raise or double up the hooks when they are added more than once" do
      SafeRequestTimeout::Hooks.add_timeout!(TestHooksDuplicate, [:thing])
      expect { SafeRequestTimeout::Hooks.add_timeout!(TestHooksDuplicate, [:thing]) }.not_to raise_error
      expect(TestHooksDuplicate.ancestors.count { |mod| mod.name.to_s.end_with?("AddTimeout") }).to eq 1

      object = TestHooksDuplicate.new
      expect(object.thing(1)).to eq 1
      SafeRequestTimeout.timeout(0.1) do
        sleep 0.11
        expect { object.thing(1) }.to raise_error(SafeRequestTimeout::TimeoutError)
      end
    end
    it "should inject timeout checks into specified methods" do
      object = TestHooks.new
      SafeRequestTimeout::Hooks.add_timeout!(TestHooks, [:thing_1, :thing_2, :thing_3])

      expect(object.thing_1(1)).to eq 1
      expect(object.thing_2(arg: 2)).to eq 2
      expect(object.thing_3(1, arg_2: 2) { |x, y| x + y }).to eq 3

      SafeRequestTimeout.timeout(0.1) do
        expect(object.thing_1(1)).to eq 1
        expect(object.thing_2(arg: 2)).to eq 2
        expect(object.thing_3(1, arg_2: 2) { |x, y| x + y }).to eq 3
        expect(object.thing_4(4)).to eq 4

        sleep 0.11

        expect(object.thing_4(4)).to eq 4
        expect { object.thing_1(1) }.to raise_error(SafeRequestTimeout::TimeoutError)
      end
    end
  end
end
