CloudServersVpc::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
end

# Optional prefix for cloud server names.
ENV['SERVER_NAME_PREFIX'] = ""

# List any authorized ssh public keys that should get installed on the cloud
# servers to provide keyless SSH access.
#ENV['AUTHORIZED_KEYS'] = ""

# Optional EPEL_BASE_URL. Use this option to specify a specific EPEL
# mirror to be used by Redhat/Centos images.
#ENV['EPEL_BASE_URL'] = ""

# Specify the default Resque Redis URL (defaults to localhost)
# Resque.redis="redis://localhost:6379"
