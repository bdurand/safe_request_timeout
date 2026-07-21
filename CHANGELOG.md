# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.3

### Fixed
- Removed unused runtime dependency on the redis gem.
- The ActiveJob timeout block no longer clears a timeout already established for the request or worker running the job (e.g. jobs run with `perform_now` inside a request, or ActiveJob jobs running with the Sidekiq middleware).
- `SafeRequestTimeout.check_timeout!` no longer raises a second error from an enclosing timeout block when a deadline shared by nested timeout blocks has already raised.
- ActiveRecord hooks no longer require a live database connection when they are installed. They are now added to each adapter class the first time a connection is instantiated, so applications that boot while the database is unavailable and applications with multiple databases are fully covered.
- Registering the same hooks more than once is now a no-op instead of raising an error.
- The transaction commit hook now clears the timeout after the commit succeeds instead of before it runs.

### Changed
- Timeout state is stored in `ActiveSupport::IsolatedExecutionState` when available (ActiveSupport 7+) so that it follows the application's configured isolation level. Otherwise it is stored in fiber-local variables as before.
- ActiveJob and ActiveRecord integrations in the Railtie are now set up with lazy load hooks instead of loading the frameworks during initialization.

## 1.0.2

### Added
- Added support for ActiveRecord 7.1.

## 1.0.1

### Fixed
- Handle case in Railtie where database connection not available.

## 1.0.0

### Added
- Initial release.