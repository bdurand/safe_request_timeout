# Request Timeout

[![Continuous Integration](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/request_timeout/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

:construction:

This gem provides a safe and convenient mechanism for adding a timeout mechanism for a block of code. The gem ensures that the timeout is safe to call and will not raise timeout errors from random places in your code which can leave your application in an indeterminate state.

It is designed to work in situations where there is a general timeout needed on some kind of request. For instance, consider a Rack HTTP request. This request may be behind a web server process which already has it's own timeout where it sends an error back to the client when the request is taking too long to process. However, your Ruby application won't know anything about this and will continue processing the request and generating a response for a client that is no longer going to receive the response which just wastes server resources.

When requests start timing out due to an external issue like a slow database query, then this behavior makes it more difficult to recover and can cascade an isolated issue into a general site outage. Often the timeouts you have on those resources won't cover this case either since individual queries never hit the timeout limit.

Unlike the `Timeout` class in the Ruby standard library, this code is very explicit about where timeout errors can be raised, so you don't need to worry about a timeout leaving your application in an indeterminate state.

## Usage

You can wrap any block in a timout block.

```ruby
RequestTimeout.timeout(15) do
   ...
end
```

By itself, this won't do anything. Unlike normal timeouts, there is no background process that will kill the operation after a defined period. Instead, you will need to periodically call `RequestTimeout.check_timeout!` from within your code. Calling this method within a timeout block will raise an error if the time spent in that block has exceeded the max allowed. It's always best to call it before doing an expensive operation since there's no point in timing out if we've already done the work. This method will also clear the current timeout, so you don't have to worry about it generating a cascading series of timeout errors.

```ruby
RequestTimeout.timeout(5) do
  1000.times do
    # This will raise an error if the loop takes longer than 5 seconds.
    RequestTimeout.check_timeout!
    do_somthing
  end
end
```

You can also set a timeout value retroactively from within a `timeout` block. You may want to use this you need to change the timeout based on application state.

```ruby
# Setting a timeout of nil will set up a block that will never timout.
RequestTimeout.timeout(nil) do
  # Retroactively set the timeout duration to 5 seconds for non-admin users
  RequestTimeout.set_timeout(5) unless current_user.admin?
end
```

You can also set the timeout duration with a `Proc` that will be evaluated at runtime.

```ruby
RequestTimeout.timeout(lambda { CurrentUser.new.admin? ? nil : 5 })
  ...
end
```

You can also clear any timeouts if you want to ensure a block of code can run without begin timed out (i.e. if you need to run cleanup code).

```ruby
RequestTimeout.timeout(5) do
  begin
    do_something
  ensure
    RequestTimeout.clear_timeout
    cleanup_request
  end
end
```

### Hooks

You can add hooks into other classes to check the current timeout if you don't want to have to sprinkle `RequestTimeout.check_timeout!` throughout your code. To do this, use the `RequestTimeout.add_timeout!` method. You need to specify the class and methods where you want to add the timeout hooks:

```ruby
# Add a timeout check to the MyDriver#make_request method.
RequestTimeout::Hooks.add_timeout!(MyDriver, [:make_request])
```

### Rack Middleware

This gem ships with Rack middleware that can set up a timeout block on all Rack requests. In a Rails application you would use this code to add a 15 second timeout to all requests.

```ruby
Rails.configuration.middleware.use RequestTimeout::RackMiddleware, 15
```

If you want to customize the timeout per request, you can call `RequestTimeout.set_timeout` inside your request handling to change the value for the current request. You can also define the timeout duration with a `Proc` which will be called a runtime.

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

### Rails

This gem comes with built in support for Rails applications.

- The Rack middleware is added. By default there is no timeout value set. You can specify a global one by setting `request_timout.rack_timeout` in your Rails configuration.

- The Sidekiq middleware is added. Sidekiq workers can specify a timeout with the `request_timeout` option.

- A timeout block is added around ActiveJob execution. Jobs can specify a timeout by calling `RequestTimeout.set_timeout` in the `perform` method or in a `before_perform` callback.

- A timeout check is added on all ActiveRecord queries. You can disable this hook by setting `request_timeout.active_record_hook` to false in your Rails configuration.

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
