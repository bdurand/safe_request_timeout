# Request Timeout

[![Continuous Integration](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

## Usage

TODO

### Hooks

ActiveSupport.on_load(:active_record) do
  RequestTimeout::Hooks.auto_setup!
end

### Rack Middleware

config.middleware.use RequestTimeout::RackMiddleware

### Sidekiq Middleware

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add RequestTimeout::SidekiqMiddleware
  end
end

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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
