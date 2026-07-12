# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(SafeRequestTimeout::Railtie)
  if defined?(ActiveJob)
    class RailtieTestJob < ActiveJob::Base
      class << self
        attr_accessor :time_remaining, :time_elapsed
      end

      def perform
        self.class.time_remaining = SafeRequestTimeout.time_remaining
        self.class.time_elapsed = SafeRequestTimeout.time_elapsed
      end
    end
  end

  describe SafeRequestTimeout::Railtie do
    it "adds the timeout hooks to ActiveRecord" do
      modules = ActiveRecord::Base.connection_pool.with_connection { |connection| connection.class.included_modules }
      expect(modules.detect { |m| m.name.to_s.end_with?("AddTimeout") }).to_not be_nil
      expect(modules.detect { |m| m.name.to_s.end_with?("ClearTimeout") }).to_not be_nil
    end

    if defined?(ActiveJob)
      describe "ActiveJob" do
        before do
          ActiveJob::Base.logger = Logger.new(File::NULL)
          RailtieTestJob.time_remaining = nil
          RailtieTestJob.time_elapsed = nil
        end

        it "opens a timeout context around job execution" do
          RailtieTestJob.perform_now
          expect(RailtieTestJob.time_elapsed).to_not be nil
          expect(RailtieTestJob.time_remaining).to be nil
        end

        it "preserves a timeout established outside of the job" do
          SafeRequestTimeout.timeout(10) do
            RailtieTestJob.perform_now
          end
          expect(RailtieTestJob.time_remaining).to be > 0
        end
      end
    end
  end
end
