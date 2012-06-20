# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
CloudServersVpc::Application.initialize!

CLOUD_SERVERS_VPC_VERSION="3.0.1"

# load in the jobs classes
Dir[File.join(File.dirname(__FILE__), '..', 'app', 'models', 'jobs', '*')].each do |job|
require job
end
