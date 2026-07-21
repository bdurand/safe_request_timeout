# Safe Request Timeout

[![Continuous Integration](https://github.com/bdurand/safe_request_timeout/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/safe_request_timeout/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/safe_request_timeout.svg)](https://badge.fury.io/rb/safe_request_timeout)

This gem provides a safe and convenient mechanism for adding a timeout mechanism to a block of code. The gem ensures that the timeout is safe to call and will not raise timeout errors from random places in your code which can leave your application in an indeterminate state.

It is designed to work in situations where there is a general timeout needed on some kind of request. For instance, consider a Rack HTTP request. This request may be behind a web server running in a separate process with it's own timeout where it sends an error back to the client when the application is taking too long to process the request. However, your Ruby application won't know anything about this and will continue processing the request and generating a response for a client that is no longer going to receive the response which just wastes server resources.

When requests start timing out due to an external issue like a slow database query, then it is more difficult to recover and can cascade an isolated issue into a general site outage. Often the timeouts you have on resources like database connections won't cover this case either since individual queries might never hit the timeout limit.

Unlike the `Timeout` class in the Ruby standard library, this code is very explicit about where timeout errors can be raised, so you don't need to worry about a timeout error in an unexpected place leaving your application in an indeterminate state.

There is built in support for Rails applications. For other frameworks you will need to add some middleware and hooks to implement the timeout mechanism.

## Usage

You can wrap code in a timeout block.

```ruby
SafeRequestTimeout.timeout(15) do
   ...
end
```

By itself, this won't do anything. Unlike normal timeouts, there is no background process that will kill the operation after a defined period. Instead, you will need to periodically call `SafeRequestTimeout.check_timeout!` from within your code. Calling this method within a timeout block will raise an error if the time spent in that block has exceeded the max allowed. Calling it outside of a timeout block will do nothing.

It is generally best to call the `check_timeout!` method before doing an expensive operation since there's no point in timing out after the work has already been done. This method will also clear the current timeout, so you don't have to worry about it generating a cascading series of timeout errors in any error handling code.

```ruby
SafeRequestTimeout.timeout(5) do
  1000.times do
    # This will raise an error if the loop takes longer than 5 seconds.
    SafeRequestTimeout.check_timeout!
    do_something
  end
end
```

You can also set a timeout value retroactively from within a `timeout` block. You can use this feature to change the timeout based on application state.

```ruby
# Setting a timeout of nil will set up a block that will never time out.
SafeRequestTimeout.timeout(nil) do
  # Set the timeout duration to 5 seconds for non-admin users
  SafeRequestTimeout.set_timeout(5) unless current_user.admin?

  do_something
end
```

You can also set the timeout duration with a `Proc` that will be evaluated at runtime.

```ruby
SafeRequestTimeout.timeout(lambda { CurrentUser.new.admin? ? nil : 5 })
  ...
end
```

You can clear the timeout if you want to ensure a block of code can run without being timed out (i.e. if you need to run cleanup code).

```ruby
SafeRequestTimeout.timeout(5) do
  begin
    do_something
  ensure
    SafeRequestTimeout.clear_timeout
    cleanup_request
  end
end
```

### Behavior notes

- Timeout blocks can be nested. A nested block will use the soonest deadline of the nested blocks, so a nested block cannot extend a timeout set by an enclosing block. Calling `set_timeout` inside a nested block, however, replaces the deadline for that block even if it extends past the enclosing block's deadline; the enclosing deadline is restored when the nested block exits.

- `SafeRequestTimeout::TimeoutError` is a subclass of `Timeout::Error` from the Ruby standard library. Generic error handling that rescues or retries on `Timeout::Error` will catch it as well.

- The timeout state is stored per thread or fiber. When ActiveSupport 7+ is available, the state is stored in `ActiveSupport::IsolatedExecutionState` and follows the application's configured `active_support.isolation_level`. Otherwise the state is stored in fiber-local variables. In either case, the timeout will not be visible in new threads spawned within a timeout block (including ActiveRecord `load_async` queries), so `check_timeout!` calls in those threads will do nothing.

### Hooks

You can add hooks into other classes to check the current timeout if you don't want to have to sprinkle `SafeRequestTimeout.check_timeout!` throughout your code. To do this, use the `SafeRequestTimeout::Hooks.add_timeout!` method. You need to specify the class and methods where you want to add the timeout hooks:

```ruby
# Add a timeout check to the MyDriver#make_request method.
SafeRequestTimeout::Hooks.add_timeout!(MyDriver, [:make_request])
```

### Rack Middleware

This gem ships with Rack middleware that can set up a timeout block on all Rack requests. In a Rack application you would use this code to add a 15 second timeout to all requests to `app`.

```ruby
RackBuilder.new do
  use SafeRequestTimeout::RackMiddleware, 15
  run app
end
```

If you want to customize the timeout per request, you can call `SafeRequestTimeout.set_timeout` inside your request handling to change the value for the current request. You can also define the timeout duration with a `Proc` which will be called at runtime with the `env` object passed for the request.

```ruby
RackBuilder.new do
  use SafeRequestTimeout::RackMiddleware, lambda { |env|
    10 unless Rack::Request.new(env).path.start_with?("/admin")
  }
  run app
end
```

### Sidekiq Middleware

This gem ships with Sidekiq middleware that can add timeout support to Sidekiq workers. The middleware needs to be added to the server middleware in the Sidekiq initialization.

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SafeRequestTimeout::SidekiqMiddleware
  end
end
```

You can then specify a timeout per worker with the `safe_request_timeout` sidekiq option.

```
class SlowWorker
  include Sidekiq::Worker

  # Set a 15 second timeout for the worker to finish.
  sidekiq_options safe_request_timeout: 15
end
```

### Rails

This gem comes with built in support for Rails applications.

- The Rack middleware is added to the middleware chain. There is no timeout value set by default. You can specify a global one by setting `safe_request_timeout.rack_timeout` in your Rails configuration.

- If Sidekiq is being used, then the Sidekiq middleware is added. Sidekiq workers can specify a timeout with the `safe_request_timeout` option.

- A timeout block is added around ActiveJob execution. Jobs can specify a timeout by calling `SafeRequestTimeout.set_timeout` in the `perform` method or in a `before_perform` callback. If a timeout has already been set up for the request or worker running the job (i.e. a job run with `perform_now` inside a request, or an ActiveJob running on Sidekiq with the Sidekiq middleware), then that timeout is kept rather than replaced.

- A timeout check is added on all ActiveRecord queries. The timeout is cleared when a database transaction is committed so that you won't unexpectedly timeout a request after making persistent changes. You can disable these hooks by setting `safe_request_timeout.active_record_hook` to false in your Rails configuration. The hooks are installed on each database adapter class the first time a connection is instantiated, so no database connection is required at boot time and all databases in a multiple database configuration are covered.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'safe_request_timeout'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install safe_request_timeout
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
