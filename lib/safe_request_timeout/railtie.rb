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
        rescue ActiveRecord::ActiveRecordError => e
          Rails.logger&.warn("Could not add ActiveRecord hook for SafeRequestTimeout: #{e.inspect}")
        end
      end

      if defined?(ActiveJob::Base.around_perform)
        ActiveJob::Base.around_perform do |job, block|
          SafeRequestTimeout.timeout(nil, &block)
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
