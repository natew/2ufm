STDOUT.sync = true
# require "memcached/rails"

Paperclip.options[:command_path] = "/usr/local/bin/"

Fusefm::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Caching
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store
  # config.cache_store = :mem_cache_store

  config.eager_load = false

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.delay_jobs = false

  config.action_mailer.default_url_options = { :host => 'localhost:5100' }

  # mails_viewer gem
  config.action_mailer.delivery_method = :file
end