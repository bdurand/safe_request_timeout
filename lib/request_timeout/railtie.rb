# frozen_string_literal: true

module RequestTimeout
  class Railtie < Rails::Railtie
    config.request_timeout = ActiveSupport::OrderedOptions
    config.request_timeout.active_record_hook = true
    config.request_timeout.rack_timeout = nil

    initializer "request_timeout" do |app|
      if app.config.request_timeout.active_record_hook
        ActiveSupport.on_load(:active_record) do
          RequestTimeout::ActiveRecordHook.add_timeout!
        end
      end

      if defined?(ActiveJob::Base.around_perform)
        ActiveJob::Base.around_perform do |job, block|
          RequestTimeout.timeout(nil, &block)
        end
      end

      app.middleware.use RequestTimeout::RackMiddleware, app.config.request_timeout.rack_timeout

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
