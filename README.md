# Request Timeout

[![Continuous Integration](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

## Usage

TODO

### Hooks

You can hook all the bundled hooks by calling `auto_setup!` when initializing your application.

```ruby
RequestTimeout::Hooks.auto_setup!
```

`ActiveRecord` requires the connection to be configured first, so you should use `ActiveSupport.on_load` in a Rails application to ensure the correct initialization order.

```ruby
ActiveSupport.on_load(:active_record) do
  RequestTimeout::Hooks.auto_setup!
end
```

You can also enable just specific hooks.

```ruby
RequestTimeout::Hooks::ActiveRecord.new.add_timeout!
```

There are hooks bundle in this gem for several popular database adapaters and HTTP libraries.

- ActiveRecord
- Redis
- Dalli
- Bunny (RabbitMQ)
- Cassandra
- Net::HTTP
- HTTP
- HTTPClient
- Typhoeus
- Curb
- Excon

You can easily hook into other libraries as well. You need to identify the classes and methods where you want to add the timeout hooks. You can then pass these into the `add_timeout!` method to prepend a timeout check to the method.

```ruby
# Add a timeout check to the MyDriver#make_request method.
RequestTimeout::Hooks.add_timeout!(MyDriver, [:make_request])
```

### Rack Middleware

This gem ships with Rack middleware that can set up a timeout block on all Rack requests. In a Rails application you would use this code to add a 15 second timeout to all requests.

```ruby
Rails.configuration.middleware.use RequestTimeout::RackMiddleware, 15
```

### Sidekiq Middleware

This gem ships with Sidekiq middleware that can add timeout support to Sidekiq workers. The middleware needs to be added to the server middleware in the Sidekiq initialization.

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add RequestTimeout::SidekiqMiddleware
  end
end
```

You can then specify a timeout per worker with the `request_timeout` sidekiq option.

```
class SlowWorker
  include Sidekiq::Worker

  # Set a 15 second timeout for the worker to finish.
  sidekiq_options request_timeout: 15
end
```

## Installation

_TODO: this tool is currently under construction and has not been published to rubygems.org yet. You can still install directly from GitHub._

Add this line to your application's Gemfile:

```ruby
gem 'request_timeout'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install request_timeout
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

Hooks for other common libraries are always appreciated.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
