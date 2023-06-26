# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(SafeRequestTimeout::Railtie)
  describe SafeRequestTimeout::Railtie do
    it "adds the timeout hooks to ActiveRecord" do
      modules = ActiveRecord::Base.connection.class.included_modules
      expect(modules.detect { |m| m.name.end_with?("AddTimeout") }).to_not be_nil
      expect(modules.detect { |m| m.name.end_with?("ClearTimeout") }).to_not be_nil
    end
  end
end
