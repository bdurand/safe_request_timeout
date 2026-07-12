# frozen_string_literal: true

module SafeRequestTimeout
  class Railtie < Rails::Railtie
    config.safe_request_timeout = ActiveSupport::OrderedOptions.new
    config.safe_request_timeout.active_record_hook = true
    config.safe_request_timeout.rack_timeout = nil

    initializer "safe_request_timeout" do |app|
      if app.config.safe_request_timeout.active_record_hook
        ActiveSupport.on_load(:active_record) do
          SafeRequestTimeout::ActiveRecordHook.add_timeout!
        rescue => e
          Rails.logger&.warn("Could not add ActiveRecord hook for SafeRequestTimeout: #{e.inspect}")
        end
      end

      ActiveSupport.on_load(:active_job) do
        around_perform do |job, block|
          # Open a timeout context so jobs can call set_timeout, but don't replace a timeout
          # already established for the request or worker that is running the job.
          if SafeRequestTimeout.time_elapsed
            block.call
          else
            SafeRequestTimeout.timeout(nil, &block)
          end
        end
      end

      app.middleware.use SafeRequestTimeout::RackMiddleware, app.config.safe_request_timeout.rack_timeout

      if defined?(Sidekiq.server?) && Sidekiq.server?
        Sidekiq.configure_server do |sidekiq_config|
          sidekiq_config.server_middleware do |chain|
            chain.add SafeRequestTimeout::SidekiqMiddleware
          end
        end
      end
    end
  end
end
