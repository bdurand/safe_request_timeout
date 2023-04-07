# frozen_string_literal: true

module RequestTimeout
  class Railtie < Rails::Railtie
    initializer "request_timeout" do |app|
      ActiveSupport.on_load(:active_record) do
        RequestTimeout::ActiveRecordHook.add_timeout!
      end

      app.config.rack_request_timeout = nil unless defined?(app.config.rack_request_timeout)
      app.middleware.use RequestTimeout::RackMiddleware, app.config.rack_request_timeout

      if defined?(Sidekiq.server?) && Sidekiq.server?
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add RequestTimeout::SidekiqMiddleware
          end
        end
      end
    end
  end
end
