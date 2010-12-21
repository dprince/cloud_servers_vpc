# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cloud_server_vpc-_session',
  :secret      => '1ca4e7bce60d9b50970eecb20f545f0a97a6d410525f71d3278605afd21e5af7f5a6265bdfafb3d0d586f5b79cbb50e7c6e3a5a6f49638f10c76b5f3199934d3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
