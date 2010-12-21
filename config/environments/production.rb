# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
config.log_level = :warn

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Enable threaded mode
# config.threadsafe!

#ENV['RACKSPACE_CLOUD_USERNAME'] = "test"
#ENV['RACKSPACE_CLOUD_API_KEY'] = "test"

# Optional prefix for cloud server names.
ENV['RACKSPACE_CLOUD_SERVER_NAME_PREFIX'] = ""

# List any authorized ssh public keys that should get installed on the cloud
# servers to provide keyless SSH access.
# ENV['CC_AUTHORIZED_KEYS'] = ""

# Optional EPEL_BASE_URL. Use this option to specify a specific EPEL
# mirror to be used by Redhat/Centos images.
# ENV['EPEL_BASE_URL'] = ""

# Specify the default Resque Redis URL (defaults to localhost)
# Resque.redis="redis://localhost:6379"
