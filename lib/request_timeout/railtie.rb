# frozen_string_literal: true

module RequestTimeout
  class Railtie < Rails::Railtie
    Rails.configuration.request_timeout ||= nil

    initializer "request_timeout" do
      ActiveSupport.on_load(:active_record) do
        RequestTimeout::ActiveRecordHook.add_timeout!
      end

      Rails.configuration.middleware.use RequestTimeout::RackMiddleware, -> { Rails.configuration.request_timeout }

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
