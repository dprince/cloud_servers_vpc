# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

#ENV['RACKSPACE_CLOUD_USERNAME'] = ""
#ENV['RACKSPACE_CLOUD_API_KEY'] = ""

# Optional prefix for cloud server names.
ENV['RACKSPACE_CLOUD_SERVER_NAME_PREFIX'] = ""

# List any authorized ssh public keys that should get installed on the cloud
# servers to provide keyless SSH access.
#ENV['CC_AUTHORIZED_KEYS'] = ""

# Optional EPEL_BASE_URL. Use this option to specify a specific EPEL
# mirror to be used by Redhat/Centos images.
#ENV['EPEL_BASE_URL'] = ""
